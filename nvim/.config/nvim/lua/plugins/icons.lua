-- mini.icons replaces nvim-web-devicons. The init() hook registers a Lua
-- package.preload entry so any plugin that does `require("nvim-web-devicons")`
-- transparently gets the mini.icons mock. Must load before any consumer.
return {
	"nvim-mini/mini.icons",
	version = false,
	lazy = false,
	opts = {
		style = "glyph",
	},
	init = function()
		package.preload["nvim-web-devicons"] = function()
			require("mini.icons").mock_nvim_web_devicons()
			return package.loaded["nvim-web-devicons"]
		end
	end,
}
