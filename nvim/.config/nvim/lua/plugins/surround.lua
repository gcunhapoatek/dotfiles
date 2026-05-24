return {
	"kylechui/nvim-surround",
	version = "^4.0.0",
	event = "VeryLazy",
	-- Visual `S` collides with flash.nvim's treesitter jump; remap to `gs`/`gS`.
	-- v4 dropped the `keymaps` setup field — disable defaults via `vim.g` and
	-- bind `<Plug>` mappings directly.
	init = function()
		vim.g.nvim_surround_no_visual_mappings = true
	end,
	keys = {
		{ "gs", "<Plug>(nvim-surround-visual)", mode = "x", desc = "Surround visual selection" },
		{ "gS", "<Plug>(nvim-surround-visual-line)", mode = "x", desc = "Surround visual selection (line)" },
	},
	opts = {},
}
