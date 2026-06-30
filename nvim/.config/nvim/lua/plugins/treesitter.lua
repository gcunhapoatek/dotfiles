-- nvim-treesitter `main` branch API differs from `master`:
--   * no opts.ensure_installed / opts.highlight / opts.indent
--   * no lazy-loading
--   * parsers installed via require('nvim-treesitter').install({...})
--   * highlight enabled via FileType autocmd calling vim.treesitter.start()
--   * indent enabled via vim.bo.indentexpr per filetype
-- See: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local ensure_installed = {
			"angular",
			"bash",
			"c",
			"comment",
			"css",
			"diff",
			"dockerfile",
			"gitcommit",
			"gitignore",
			"go",
			"html",
			"javascript",
			"json",
			"lua",
			"luadoc",
			"luap",
			"markdown",
			"markdown_inline",
			"python",
			"query",
			"regex",
			"rust",
			"toml",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"yaml",
		}
		require("nvim-treesitter").install(ensure_installed)

		-- Angular templates resolve to filetype `htmlangular` (nvim 0.11+); point
		-- it at the `angular` parser so the FileType autocmd below starts it.
		vim.treesitter.language.register("angular", "htmlangular")

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true }),
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
				if lang and pcall(vim.treesitter.start, args.buf, lang) then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
