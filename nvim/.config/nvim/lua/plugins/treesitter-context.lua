-- Sticky function/class header at the top of the viewport. Driven by the
-- already-installed treesitter parsers; no extra setup beyond this spec.
return {
	"nvim-treesitter/nvim-treesitter-context",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		enable = true,
		max_lines = 3,
		min_window_height = 20,
		line_numbers = true,
		multiline_threshold = 1,
		trim_scope = "outer",
		mode = "cursor",
		zindex = 20,
	},
	keys = {
		{
			"[c",
			function()
				require("treesitter-context").go_to_context(vim.v.count1)
			end,
			desc = "Jump to context (upwards)",
		},
		{ "<leader>uC", "<cmd>TSContext toggle<cr>", desc = "Toggle treesitter context" },
	},
}
