return {
	"akinsho/bufferline.nvim",
	version = "*",
	event = "VeryLazy",
	dependencies = { "nvim-mini/mini.icons", "catppuccin/nvim" },
	keys = {
		{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Toggle pin" },
		{ "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Delete non-pinned buffers" },
		-- `<leader>bo` (delete other buffers) is owned by Snacks.bufdelete.other,
		-- which preserves the window layout. See plugins/snacks.lua.
		{ "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Delete buffers to the right" },
		{ "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Delete buffers to the left" },
		{ "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
		{ "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
	},
	opts = function()
		return {
			options = {
				mode = "buffers",
				themable = true,
				numbers = "none",
				close_command = function(n)
					Snacks.bufdelete(n)
				end,
				right_mouse_command = function(n)
					Snacks.bufdelete(n)
				end,
				diagnostics = "nvim_lsp",
				diagnostics_indicator = function(_, _, diag)
					local icons = { Error = " ", Warn = " ", Info = " " }
					local ret = (diag.error and icons.Error .. diag.error .. " " or "")
						.. (diag.warning and icons.Warn .. diag.warning or "")
					return vim.trim(ret)
				end,
				always_show_bufferline = true,
				show_buffer_close_icons = true,
				show_close_icon = false,
				separator_style = "slant",
				offsets = {
					{
						filetype = "snacks_layout_box",
					},
				},
				---@param opts bufferline.IconFetcherOpts
				get_element_icon = function(opts)
					local icon, hl = require("mini.icons").get("filetype", opts.filetype)
					return icon, hl
				end,
			},
			highlights = require("catppuccin.special.bufferline").get_theme({
				styles = { "italic", "bold" },
				custom = {
					all = {
						fill = { bg = "NONE" },
						background = { bg = "NONE" },
						buffer_visible = { bg = "NONE" },
						buffer_selected = { bg = "NONE" },
						separator = { bg = "NONE" },
						separator_visible = { bg = "NONE" },
						separator_selected = { bg = "NONE" },
					},
				},
			}),
		}
	end,
}
