return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    opts = {
      auto_install = true,
      ensure_installed = {
        "bash",
        "javascript",
        "typescript",
        "json",
        "lua",
        "markdown",
      },
      highlight = { enable = true },
      indent = { enable = false },
    },
  }
}
