-- Formatter pipeline. format_on_save falls back to LSP when no formatter is
-- configured; per-buffer / global flags let you disable autoformat via
-- :FormatDisable and :FormatEnable.

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_format", "ruff_organize_imports" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			vue = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			jsonc = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
			html = { "prettierd", "prettier", stop_after_first = true },
			css = { "prettierd", "prettier", stop_after_first = true },
			scss = { "prettierd", "prettier", stop_after_first = true },
			markdown = { "prettierd", "prettier", stop_after_first = true },
			go = { "goimports", "gofumpt" },
			rust = { "rustfmt", lsp_format = "fallback" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			zsh = { "shfmt" },
		},
		default_format_opts = {
			lsp_format = "fallback",
			timeout_ms = 1500,
		},
		format_on_save = function(bufnr)
			if vim.b[bufnr].disable_autoformat or vim.g.disable_autoformat then
				return
			end
			return { timeout_ms = 1500, lsp_format = "fallback" }
		end,
		formatters = {
			shfmt = { prepend_args = { "-i", "2", "-ci" } },
		},
	},
	init = function()
		vim.api.nvim_create_user_command("FormatDisable", function(args)
			if args.bang then
				vim.b.disable_autoformat = true
			else
				vim.g.disable_autoformat = true
			end
		end, { desc = "Disable autoformat-on-save", bang = true })

		vim.api.nvim_create_user_command("FormatEnable", function()
			vim.b.disable_autoformat = false
			vim.g.disable_autoformat = false
		end, { desc = "Enable autoformat-on-save" })
	end,
}
