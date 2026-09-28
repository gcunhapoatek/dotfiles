return {
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				transparent_background = true,
				-- transparent_background only clears Normal/Pmenu; this also clears
				-- NormalFloat/FloatBorder/FloatTitle, which snacks picker, explorer,
				-- notifier and input link to. Selection groups keep their colors.
				float = { transparent = true, solid = false },
			})
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
}
