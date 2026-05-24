-- LSP stack: mason installs servers/tools, nvim-lspconfig provides server
-- specs, blink.cmp supplies completion capabilities. Server enablement uses
-- the nvim 0.11+ vim.lsp.config / vim.lsp.enable APIs via mason-lspconfig 2.x.

local servers = {
	lua_ls = {
		settings = {
			Lua = {
				workspace = { checkThirdParty = false },
				diagnostics = { globals = { "vim", "Snacks" } },
				hint = { enable = true },
				telemetry = { enable = false },
				format = { enable = false },
			},
		},
	},
	vtsls = {
		settings = {
			typescript = {
				inlayHints = {
					parameterNames = { enabled = "literals" },
					variableTypes = { enabled = true },
					propertyDeclarationTypes = { enabled = true },
					functionLikeReturnTypes = { enabled = true },
				},
			},
			javascript = {
				inlayHints = {
					parameterNames = { enabled = "literals" },
					variableTypes = { enabled = true },
				},
			},
		},
	},
	html = {},
	cssls = {},
	jsonls = {},
	basedpyright = {
		settings = {
			basedpyright = {
				analysis = {
					typeCheckingMode = "standard",
					diagnosticMode = "openFilesOnly",
					inlayHints = { variableTypes = true, callArgumentNames = true },
				},
			},
		},
	},
	ruff = {
		-- Defer hover to basedpyright so we get pyright's richer type info.
		on_attach = function(client)
			client.server_capabilities.hoverProvider = false
		end,
	},
	gopls = {
		settings = {
			gopls = {
				gofumpt = true,
				usePlaceholders = true,
				completeUnimported = true,
				staticcheck = true,
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
			},
		},
	},
	rust_analyzer = {
		settings = {
			["rust-analyzer"] = {
				cargo = { allFeatures = true },
				check = { command = "clippy" },
			},
		},
	},
	bashls = {},
}

return {
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog", "MasonUninstall" },
		opts = {
			ui = { border = "rounded" },
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		event = "VeryLazy",
		opts = {
			run_on_start = true,
			auto_update = false,
			ensure_installed = {
				"stylua",
				"prettierd",
				"gofumpt",
				"goimports",
				"shfmt",
				"shellcheck",
				"eslint_d",
				"golangci-lint",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "mason-org/mason-lspconfig.nvim", dependencies = { "mason-org/mason.nvim" } },
			"saghen/blink.cmp",
		},
		config = function()
			local virtual_text_opts = {
				spacing = 4,
				source = "if_many",
				prefix = "●",
			}
			vim.diagnostic.config({
				severity_sort = true,
				underline = true,
				update_in_insert = false,
				virtual_text = virtual_text_opts,
				virtual_lines = false,
				float = { border = "rounded", source = "if_many" },
				-- Replaces the deprecated `float = true` option to
				-- vim.diagnostic.jump(). on_jump fires once per jump and
				-- pops the float for the diagnostic landed on.
				jump = {
					on_jump = function(_, _)
						vim.diagnostic.open_float()
					end,
				},
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.INFO] = "",
						[vim.diagnostic.severity.HINT] = "",
					},
				},
			})

			-- Toggle between inline virtual_text and expanded virtual_lines.
			-- virtual_lines.current_line = true keeps noise low: only the
			-- diagnostic for the cursor's line is expanded.
			vim.keymap.set("n", "<leader>ux", function()
				local cfg = vim.diagnostic.config() or {}
				if cfg.virtual_lines then
					vim.diagnostic.config({ virtual_text = virtual_text_opts, virtual_lines = false })
					vim.notify("Diagnostics: virtual_text", vim.log.levels.INFO)
				else
					vim.diagnostic.config({ virtual_text = false, virtual_lines = { current_line = true } })
					vim.notify("Diagnostics: virtual_lines (current line)", vim.log.levels.INFO)
				end
			end, { desc = "Toggle diagnostic virtual_lines" })

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			vim.lsp.config("*", { capabilities = capabilities })
			for name, cfg in pairs(servers) do
				vim.lsp.config(name, cfg)
			end

			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_enable = true,
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
				callback = function(args)
					local buf = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local function map(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
					end

					-- Navigation via Snacks picker so results land in a fuzzy list.
					map("n", "gd", function()
						Snacks.picker.lsp_definitions()
					end, "Goto definition")
					map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
					map("n", "gr", function()
						Snacks.picker.lsp_references()
					end, "References")
					map("n", "gI", function()
						Snacks.picker.lsp_implementations()
					end, "Implementations")
					map("n", "gy", function()
						Snacks.picker.lsp_type_definitions()
					end, "Type definition")

					-- Buffer actions
					map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
					map("n", "<leader>cs", function()
						Snacks.picker.lsp_symbols()
					end, "Document symbols")
					map("n", "<leader>cS", function()
						Snacks.picker.lsp_workspace_symbols()
					end, "Workspace symbols")
					map({ "i", "s" }, "<C-k>", vim.lsp.buf.signature_help, "Signature help")

					if client and client:supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = buf })
					end

					-- Route `gq` through conform when it has a formatter for this ft.
					if package.loaded["conform"] or pcall(require, "conform") then
						vim.bo[buf].formatexpr = "v:lua.require'conform'.formatexpr()"
					end
				end,
			})
		end,
	},
}
