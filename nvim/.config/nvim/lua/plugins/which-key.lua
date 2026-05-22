return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	---@type wk.Opts
	opts = {
		preset = "modern",
		delay = 300,
		spec = {
			{ "<leader>b", group = "buffer" },
			{ "<leader>c", group = "code" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>h", group = "hunks" },
			{ "<leader>t", group = "terminal" },
			{ "<leader>u", group = "ui/toggle" },
			{ "<leader>w", group = "window" },
			{ "<leader>x", group = "diagnostics/quickfix" },
			{ "<leader>z", group = "zen" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer keymaps (which-key)",
		},
	},
}
