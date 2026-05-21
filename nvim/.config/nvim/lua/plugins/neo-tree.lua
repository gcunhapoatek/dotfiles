return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>",         desc = "Toggle file explorer" },
      { "<leader>o", "<cmd>Neotree focus<cr>",          desc = "Focus file explorer" },
      { "<leader>E", "<cmd>Neotree reveal toggle<cr>",  desc = "Reveal current file in explorer" },
    },
    opts = {
      filesystem = {
        filtered_items = {
          -- Show hidden + gitignored files (dimmed) instead of hiding them.
          -- Essential for editing dotfiles repos where every interesting
          -- file lives under .config/ or starts with a dot.
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_by_name = { ".DS_Store", ".git" },
        },
        follow_current_file = { enabled = true },
      },
    },
  },
}
