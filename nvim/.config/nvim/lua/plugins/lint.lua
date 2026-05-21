-- Linters complement LSP diagnostics. Lua/Python are handled by their LSPs
-- (lua_ls / ruff), so no entries here. JS/TS use eslint_d, Go uses
-- golangci-lint, shell uses shellcheck.

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      vue = { "eslint_d" },
      go = { "golangcilint" },
      sh = { "shellcheck" },
      bash = { "shellcheck" },
    }

    local aug = vim.api.nvim_create_augroup("user_nvim_lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = aug,
      callback = function()
        if vim.bo.modifiable then require("lint").try_lint() end
      end,
    })

    vim.api.nvim_create_user_command("Lint", function() require("lint").try_lint() end, {
      desc = "Run linters for current buffer",
    })
  end,
}
