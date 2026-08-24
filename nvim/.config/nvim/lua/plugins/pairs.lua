return {
	{
		"nvim-mini/mini.pairs",
		version = "*",
		event = { "InsertEnter", "CmdlineEnter" },
		opts = {},
	},
	{
		"windwp/nvim-ts-autotag",
		-- Only filetypes with a parser installed (see plugins/treesitter.lua) —
		-- autotag is treesitter-driven, so it is inert anywhere else. Note `tsx`
		-- and `jsx` are not nvim filetypes; the *react entries are what fire.
		ft = {
			"html",
			"htmlangular",
			"xml",
			"vue",
			"javascript",
			"typescript",
			"javascriptreact",
			"typescriptreact",
			"markdown",
		},
		opts = {
			opts = {
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = false,
			},
		},
	},
}
