-- Completion engine. Capabilities are pulled into lspconfig via
-- require('blink.cmp').get_lsp_capabilities() in plugins/lsp.lua.

return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "default" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      ghost_text = { enabled = true },
      menu = { border = "rounded" },
      list = { selection = { preselect = false, auto_insert = true } },
    },
    signature = { enabled = true, window = { border = "rounded" } },
    snippets = { preset = "default" },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
