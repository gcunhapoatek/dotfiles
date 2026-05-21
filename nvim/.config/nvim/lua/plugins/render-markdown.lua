-- Inline markdown rendering: headings, code-blocks, checkboxes, callouts,
-- tables. Active in `markdown` (and a few markdown-flavored) buffers.
-- Icon provider is nvim-web-devicons (already pulled in by bufferline / lualine).
-- Treesitter parsers needed (already in plugins/treesitter.lua): markdown,
-- markdown_inline, html, yaml.

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "Avante", "codecompanion" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    file_types = { "markdown", "Avante", "codecompanion" },
    completions = { lsp = { enabled = true } },
    code = {
      sign = false,
      width = "block",
      right_pad = 1,
    },
    heading = {
      sign = false,
      icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
    },
    checkbox = {
      enabled = true,
      unchecked = { icon = "󰄱 " },
      checked   = { icon = "󰱒 " },
    },
  },
  keys = {
    { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" },
  },
}
