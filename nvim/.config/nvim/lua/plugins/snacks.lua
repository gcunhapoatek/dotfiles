return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        explorer = {
          -- Show dotfiles and gitignored files (essential when editing
          -- this dotfiles repo: every config lives under .config/).
          hidden = true,
          ignored = true,
          exclude = { ".git", ".DS_Store" },
        },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
  keys = {
    { "<leader>e", function() Snacks.explorer() end,                         desc = "Toggle file explorer" },
    { "<leader>E", function() Snacks.explorer.reveal() end,                  desc = "Reveal current file in explorer" },
    { "<leader>n", function() Snacks.notifier.show_history() end,            desc = "Notification history" },
    { "<leader>un", function() Snacks.notifier.hide() end,                   desc = "Dismiss all notifications" },
  },
}
