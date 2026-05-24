-- nvim-treesitter-textobjects on the `main` branch does not auto-bind
-- keymaps; users must call the module functions explicitly.
return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
				selection_modes = {
					["@parameter.outer"] = "v",
					["@function.outer"] = "V",
					["@class.outer"] = "V",
				},
				include_surrounding_whitespace = false,
			},
			move = {
				set_jumps = true,
			},
		})

		local select = require("nvim-treesitter-textobjects.select")
		local move = require("nvim-treesitter-textobjects.move")
		local swap = require("nvim-treesitter-textobjects.swap")
		local map = vim.keymap.set

		local function sel(query)
			return function()
				select.select_textobject(query, "textobjects")
			end
		end

		-- Select (visual + operator-pending)
		map({ "x", "o" }, "af", sel("@function.outer"), { desc = "Function (outer)" })
		map({ "x", "o" }, "if", sel("@function.inner"), { desc = "Function (inner)" })
		map({ "x", "o" }, "ac", sel("@class.outer"), { desc = "Class (outer)" })
		map({ "x", "o" }, "ic", sel("@class.inner"), { desc = "Class (inner)" })
		map({ "x", "o" }, "aa", sel("@parameter.outer"), { desc = "Parameter (outer)" })
		map({ "x", "o" }, "ia", sel("@parameter.inner"), { desc = "Parameter (inner)" })
		map({ "x", "o" }, "ao", sel("@loop.outer"), { desc = "Loop (outer)" })
		map({ "x", "o" }, "io", sel("@loop.inner"), { desc = "Loop (inner)" })

		-- Move. `]]`/`[[` are owned by snacks.words; use `]c`/`[c` for class.
		local function goto_next_start(query)
			return function()
				move.goto_next_start(query, "textobjects")
			end
		end
		local function goto_next_end(query)
			return function()
				move.goto_next_end(query, "textobjects")
			end
		end
		local function goto_prev_start(query)
			return function()
				move.goto_previous_start(query, "textobjects")
			end
		end
		local function goto_prev_end(query)
			return function()
				move.goto_previous_end(query, "textobjects")
			end
		end

		map({ "n", "x", "o" }, "]f", goto_next_start("@function.outer"), { desc = "Next function start" })
		map({ "n", "x", "o" }, "]F", goto_next_end("@function.outer"), { desc = "Next function end" })
		map({ "n", "x", "o" }, "[f", goto_prev_start("@function.outer"), { desc = "Prev function start" })
		map({ "n", "x", "o" }, "[F", goto_prev_end("@function.outer"), { desc = "Prev function end" })
		map({ "n", "x", "o" }, "]c", goto_next_start("@class.outer"), { desc = "Next class start" })
		map({ "n", "x", "o" }, "]C", goto_next_end("@class.outer"), { desc = "Next class end" })
		map({ "n", "x", "o" }, "[c", goto_prev_start("@class.outer"), { desc = "Prev class start" })
		map({ "n", "x", "o" }, "[C", goto_prev_end("@class.outer"), { desc = "Prev class end" })
		map({ "n", "x", "o" }, "]a", goto_next_start("@parameter.inner"), { desc = "Next parameter" })
		map({ "n", "x", "o" }, "[a", goto_prev_start("@parameter.inner"), { desc = "Prev parameter" })

		-- Swap parameters
		map("n", "<leader>sa", function()
			swap.swap_next("@parameter.inner")
		end, { desc = "Swap parameter with next" })
		map("n", "<leader>sA", function()
			swap.swap_previous("@parameter.inner")
		end, { desc = "Swap parameter with previous" })
	end,
}
