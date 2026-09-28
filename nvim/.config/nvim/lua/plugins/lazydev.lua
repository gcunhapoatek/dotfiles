-- Configures lua_ls for editing this nvim config: the nvim runtime API plus
-- plugin types, loaded on demand when a matching word appears in the buffer.
-- Completion source is wired into blink.cmp in plugins/blink.lua.
return {
	"folke/lazydev.nvim",
	ft = "lua",
	opts = {
		library = {
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			{ path = "snacks.nvim", words = { "Snacks" } },
		},
	},
}
