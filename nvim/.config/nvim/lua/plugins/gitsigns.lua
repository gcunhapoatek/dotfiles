return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
      untracked    = { text = "▎" },
    },
    signs_staged = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
    },
    signs_staged_enable = true,
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 500,
      ignore_whitespace = false,
    },
    preview_config = { border = "rounded" },
    on_attach = function(buf)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
      end

      -- Hunk navigation
      map("n", "]h", function()
        if vim.wo.diff then return "]h" end
        vim.schedule(function() gs.nav_hunk("next") end)
        return "<Ignore>"
      end, "Next hunk")
      map("n", "[h", function()
        if vim.wo.diff then return "[h" end
        vim.schedule(function() gs.nav_hunk("prev") end)
        return "<Ignore>"
      end, "Prev hunk")

      -- Hunk actions
      map({ "n", "v" }, "<leader>hs", "<cmd>Gitsigns stage_hunk<cr>", "Stage hunk")
      map({ "n", "v" }, "<leader>hr", "<cmd>Gitsigns reset_hunk<cr>", "Reset hunk")
      map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
      map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
      map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
      map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
      map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")
      map("n", "<leader>hd", gs.diffthis, "Diff against index")
      map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff against last commit")

      -- Text object
      map({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<cr>", "Inside hunk")
    end,
  },
}
