return {
	"kylechui/nvim-surround",
	version = "^4.0.0",
	event = "VeryLazy",
	opts = {
		-- Visual `S` collides with flash.nvim's treesitter jump; remap to `gs`/`gS`.
		keymaps = {
			visual = "gs",
			visual_line = "gS",
		},
	},
}
