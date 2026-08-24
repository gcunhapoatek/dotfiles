vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3
opt.pumheight = 10
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = {
	eob = " ",
	fold = " ",
	foldopen = "▾",
	foldsep = " ",
	foldclose = "▸",
}

-- Editing
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.autoindent = true
opt.shiftround = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"

-- Files / persistence
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.confirm = true
opt.autowrite = true

-- Splits
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- Performance / timing
opt.updatetime = 200
opt.timeoutlen = 300
opt.ttimeoutlen = 10
opt.redrawtime = 1500

-- Floating windows. Single source of truth for float borders: nvim_open_win
-- falls back to this whenever a caller passes no explicit border, so LSP hover,
-- diagnostic floats, blink.cmp, mason and gitsigns previews all inherit it.
opt.winborder = "rounded"

-- Completion / wildmenu
opt.completeopt = { "menu", "menuone", "noselect", "fuzzy" }
opt.wildmode = "longest:full,full"
opt.shortmess:append({ W = true, I = true, c = true })

-- Folding (treesitter-driven; enabled but every fold starts open)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- Per-project config: nvim 0.11+ prompts to trust .nvim.lua / .nvimrc / .exrc
-- on first load and remembers the choice via :trust.
opt.exrc = true

-- System
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.mousemoveevent = true
opt.virtualedit = "block"
opt.formatoptions = "jcroqlnt"

-- Diff
opt.diffopt:append("linematch:60")
