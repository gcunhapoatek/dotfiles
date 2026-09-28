-- LSP stack: mason installs servers/tools, nvim-lspconfig provides server
-- specs, blink.cmp supplies completion capabilities. Server enablement uses
-- the nvim 0.11+ vim.lsp.config / vim.lsp.enable APIs via mason-lspconfig 2.x.

local servers = {
	lua_ls = {
		settings = {
			Lua = {
				-- `vim` / `Snacks` types come from lazydev (plugins/lazydev.lua).
				workspace = { checkThirdParty = false },
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
	angularls = {
		-- Attaches only in Angular workspaces (root markers angular.json / nx.json),
		-- so it stays dormant in other projects. vtsls also serves rename on the
		-- shared .ts files; silence angularls's to avoid duplicate rename popups.
		on_attach = function(client)
			client.server_capabilities.renameProvider = false
		end,
	},
	eslint = {
		-- Replaces lspconfig's defaults rather than extending them: narrowed to
		-- the filetypes actually used here (svelte/astro deliberately dropped)
		-- plus `htmlangular` for Angular templates.
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"vue",
			"htmlangular",
		},
		-- No on_attach here: vim.lsp.config replaces (not chains) it, and
		-- lspconfig's default is what defines :LspEslintFixAll. The fix-on-save
		-- hook lives in the LspAttach autocmd below instead.
	},
	html = {},
	cssls = {},
	-- Schemas come from SchemaStore.nvim, resolved in before_init because this
	-- table is built before the plugin is on the runtimepath. Neither server
	-- defines its own before_init in lspconfig, so nothing is shadowed.
	jsonls = {
		before_init = function(_, config)
			config.settings.json.schemas = require("schemastore").json.schemas()
		end,
		settings = { json = { validate = { enable = true } } },
	},
	yamlls = {
		before_init = function(_, config)
			config.settings.yaml.schemas = require("schemastore").yaml.schemas()
		end,
		settings = {
			yaml = {
				-- Disable the server's built-in SchemaStore fetch; SchemaStore.nvim
				-- provides the catalog instead (per its README).
				schemaStore = { enable = false, url = "" },
			},
		},
	},
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
		opts = {},
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
				-- Not a nvim-lint linter: bashls picks it up from PATH.
				"shellcheck",
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
			{ "b0o/SchemaStore.nvim", lazy = true },
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
				float = { source = "if_many" },
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
			-- A Snacks toggle like the rest of `<leader>u` (see plugins/snacks.lua),
			-- so which-key shows its state.
			Snacks.toggle
				.new({
					name = "Diagnostic Virtual Lines",
					get = function()
						return (vim.diagnostic.config() or {}).virtual_lines ~= false
					end,
					set = function(state)
						if state then
							vim.diagnostic.config({ virtual_text = false, virtual_lines = { current_line = true } })
						else
							vim.diagnostic.config({ virtual_text = virtual_text_opts, virtual_lines = false })
						end
					end,
				})
				:map("<leader>ux")

			-- No vim.lsp.config("*", { capabilities = ... }) here: blink.cmp's
			-- plugin/ script already sets it when it loads (hence the dependency).
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
					local function map(mode, lhs, rhs, desc, opts)
						opts = vim.tbl_extend("force", { buffer = buf, desc = desc, silent = true }, opts or {})
						vim.keymap.set(mode, lhs, rhs, opts)
					end

					-- Navigation via Snacks picker so results land in a fuzzy list.
					-- `gr` is nowait: nvim's global `grr`/`grn`/`gra`/`gri`/`grt`/`grx`
					-- would otherwise make it wait out `timeoutlen` on every press.
					map("n", "gd", function()
						Snacks.picker.lsp_definitions()
					end, "Goto definition")
					map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
					map("n", "gr", function()
						Snacks.picker.lsp_references()
					end, "References", { nowait = true })
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
					-- Insert-mode `<C-k>` is left to blink.cmp's default preset, which
					-- shows its own (bordered) signature window. Binding it here would
					-- shadow blink with the plain native float in every LSP buffer.

					-- Apply all ESLint autofixes on save (rule fixes / unused imports /
					-- order); prettier still owns formatting via conform. Grouped per
					-- buffer so a re-attach (:LspRestart, reopening the buffer) replaces
					-- the hook instead of stacking another FixAll onto every save.
					if client and client.name == "eslint" then
						vim.api.nvim_create_autocmd("BufWritePre", {
							group = vim.api.nvim_create_augroup("user_eslint_fix_" .. buf, { clear = true }),
							buffer = buf,
							command = "LspEslintFixAll",
						})
					end

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
