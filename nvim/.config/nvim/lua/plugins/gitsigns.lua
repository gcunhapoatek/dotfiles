return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		signs_staged = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},
		signs_staged_enable = true,
		current_line_blame = false,
		current_line_blame_opts = { delay = 500 },
		on_attach = function(buf)
			local gs = require("gitsigns")
			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
			end

			-- Hunk navigation. No diff-mode fallback: `]h`/`[h` have no native
			-- meaning (diff-mode change jumps are `]c`/`[c`).
			map("n", "]h", function()
				gs.nav_hunk("next")
			end, "Next hunk")
			map("n", "[h", function()
				gs.nav_hunk("prev")
			end, "Prev hunk")

			-- Hunk actions. stage_hunk toggles: re-run on a staged hunk to unstage.
			-- Visual mode passes the selected lines explicitly; `<cmd>` mappings
			-- don't forward the visual range to :Gitsigns.
			map("n", "<leader>hs", gs.stage_hunk, "Stage/unstage hunk")
			map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
			map("v", "<leader>hs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Stage/unstage selected lines")
			map("v", "<leader>hr", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Reset selected lines")
			map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
			map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
			map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
			map("n", "<leader>hb", function()
				gs.blame_line({ full = true })
			end, "Blame line")
			map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")
			map("n", "<leader>hd", gs.diffthis, "Diff against index")
			map("n", "<leader>hD", function()
				gs.diffthis("~")
			end, "Diff against last commit")

			-- Text object
			map({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<cr>", "Inside hunk")
		end,
	},
}
