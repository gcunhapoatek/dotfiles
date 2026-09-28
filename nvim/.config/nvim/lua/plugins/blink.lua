-- Completion engine. On nvim 0.11+ blink's plugin/ script registers its LSP
-- capabilities via vim.lsp.config("*", ...) on load; plugins/lsp.lua lists it
-- as an lspconfig dependency so that happens before servers are enabled.

return {
	"saghen/blink.cmp",
	event = { "InsertEnter", "CmdlineEnter" },
	version = "1.*",
	dependencies = { "rafamadriz/friendly-snippets" },
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = { preset = "default" },
		appearance = { nerd_font_variant = "mono" },
		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 200 },
			ghost_text = { enabled = true },
			list = { selection = { preselect = false, auto_insert = true } },
		},
		-- `<C-k>` (default preset) toggles this; borders come from `winborder`.
		signature = { enabled = true },
		snippets = { preset = "default" },
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			-- lazydev (plugins/lazydev.lua) only makes sense in Lua buffers.
			per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
	opts_extend = { "sources.default" },
}
