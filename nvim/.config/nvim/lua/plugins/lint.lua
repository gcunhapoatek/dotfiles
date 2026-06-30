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
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
			group = aug,
			callback = function()
				if vim.bo.modifiable then
					require("lint").try_lint()
				end
			end,
		})

		vim.api.nvim_create_user_command("Lint", function()
			require("lint").try_lint()
		end, {
			desc = "Run linters for current buffer",
		})
	end,
}
