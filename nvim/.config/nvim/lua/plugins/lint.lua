-- Linters complement LSP diagnostics. Lua/Python are handled by their LSPs
-- (lua_ls / ruff) and JS/TS by the eslint LSP (diagnostics + fix-on-save), so
-- no entries here. Go uses golangci-lint, shell uses shellcheck.

return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			go = { "golangcilint" },
			sh = { "shellcheck" },
			bash = { "shellcheck" },
		}

		local aug = vim.api.nvim_create_augroup("user_nvim_lint", { clear = true })

		-- golangci-lint analyses the whole package and takes seconds, so Go lints
		-- on save only. Everything else is cheap enough to run while editing.
		local slow_fts = { go = true }

		local function lint_buf()
			if vim.bo.modifiable then
				require("lint").try_lint()
			end
		end

		vim.api.nvim_create_autocmd({ "BufReadPost", "InsertLeave" }, {
			group = aug,
			callback = function(args)
				if not slow_fts[vim.bo[args.buf].filetype] then
					lint_buf()
				end
			end,
		})

		vim.api.nvim_create_autocmd("BufWritePost", {
			group = aug,
			callback = lint_buf,
		})

		vim.api.nvim_create_user_command("Lint", function()
			require("lint").try_lint()
		end, {
			desc = "Run linters for current buffer",
		})
	end,
}
