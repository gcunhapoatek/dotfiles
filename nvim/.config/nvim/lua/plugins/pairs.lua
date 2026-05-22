return {
	{
		"nvim-mini/mini.pairs",
		version = "*",
		event = { "InsertEnter", "CmdlineEnter" },
		opts = {},
	},
	{
		"windwp/nvim-ts-autotag",
		ft = {
			"html",
			"xml",
			"svelte",
			"vue",
			"tsx",
			"jsx",
			"javascript",
			"typescript",
			"javascriptreact",
			"typescriptreact",
			"markdown",
			"astro",
			"php",
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
