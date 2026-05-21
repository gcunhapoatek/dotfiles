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
        -- Defaults shared across the file-finding sources. Each source
        -- can still override individually below.
        explorer = {
          -- Show dotfiles and gitignored files (essential when editing
          -- this dotfiles repo: every config lives under .config/).
          hidden = true,
          ignored = true,
          exclude = { ".git", ".DS_Store" },
        },
        files = {
          hidden = true,
          ignored = true,
          exclude = { ".git", ".DS_Store" },
        },
        grep = {
          hidden = true,
          ignored = true,
          exclude = { ".git", ".DS_Store" },
        },
        smart = {
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
    -- Explorer
    { "<leader>e",  function() Snacks.explorer() end,                  desc = "Toggle file explorer" },
    { "<leader>E",  function() Snacks.explorer.reveal() end,           desc = "Reveal current file in explorer" },

    -- Picker (file/text/buffer search)
    { "<leader><space>", function() Snacks.picker.smart() end,         desc = "Smart find (files + buffers + recent)" },
    { "<leader>ff", function() Snacks.picker.files() end,              desc = "Find files" },
    { "<leader>fr", function() Snacks.picker.recent() end,             desc = "Recent files" },
    { "<leader>fb", function() Snacks.picker.buffers() end,            desc = "Buffers" },
    { "<leader>fg", function() Snacks.picker.grep() end,               desc = "Live grep" },
    { "<leader>/",  function() Snacks.picker.grep() end,               desc = "Live grep" },
    { "<leader>fw", function() Snacks.picker.grep_word() end,          desc = "Grep word under cursor", mode = { "n", "x" } },

    -- Notifier
    { "<leader>n",  function() Snacks.notifier.show_history() end,     desc = "Notification history" },
    { "<leader>un", function() Snacks.notifier.hide() end,             desc = "Dismiss all notifications" },
  },
}
