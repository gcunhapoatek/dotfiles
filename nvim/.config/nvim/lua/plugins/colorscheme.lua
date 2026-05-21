return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
        integrations = {
          snacks = { enabled = true },
        },
      })
      vim.cmd.colorscheme("catppuccin-mocha")

      -- Catppuccin's transparent_background only clears the `Normal`
      -- highlight. Plugins that draw in floating windows (snacks.picker,
      -- snacks.explorer, snacks.dashboard, snacks.notifier, snacks.input,
      -- generic Telescope/cmp menus) define their own highlight groups
      -- and won't inherit Normal — so they end up painted opaque.
      -- Re-clear them on every :colorscheme call.
      local transparent_groups = {
        -- snacks.picker / snacks.explorer
        "SnacksPicker", "SnacksPickerBorder", "SnacksPickerTitle",
        "SnacksPickerInput", "SnacksPickerInputBorder", "SnacksPickerInputTitle",
        "SnacksPickerList", "SnacksPickerListCursorLine",
        "SnacksPickerPreview", "SnacksPickerPreviewBorder", "SnacksPickerPreviewTitle",
        "SnacksPickerBox", "SnacksPickerBoxBorder", "SnacksPickerBoxTitle",
        "SnacksPickerStatus",
        -- snacks.dashboard
        "SnacksDashboard", "SnacksDashboardNormal", "SnacksDashboardHeader",
        -- snacks.notifier
        "SnacksNotifier", "SnacksNotifierBorder",
        "SnacksNotifierInfo", "SnacksNotifierWarn", "SnacksNotifierError",
        -- snacks.input
        "SnacksInput", "SnacksInputBorder", "SnacksInputTitle",
        -- Generic floats
        "NormalFloat", "FloatBorder", "FloatTitle",
        "Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb",
      }

      local function clear_bg()
        for _, group in ipairs(transparent_groups) do
          vim.api.nvim_set_hl(0, group, { bg = "NONE" })
        end
      end

      clear_bg()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = clear_bg,
      })
    end,
  },
}
