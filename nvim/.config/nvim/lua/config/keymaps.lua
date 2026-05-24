local map = vim.keymap.set

-- Quicker escape
map("i", "jk", "<Esc>", { desc = "Escape insert mode" })
map("t", "<C-/>", "<C-\\><C-n>", { desc = "Escape terminal mode" })

-- Save / quit
map({ "n", "i", "v" }, "<C-s>", "<cmd>silent! write<cr><Esc>", { desc = "Save file" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>confirm quit<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>confirm qall<cr>", { desc = "Quit all" })

-- Clear search highlight
map({ "i", "n" }, "<Esc>", "<cmd>noh<cr><Esc>", { desc = "Escape and clear hlsearch" })

-- Better up/down on wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Window resize
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Window split
map("n", "<leader>-", "<C-w>s", { desc = "Split window below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split window right" })
map("n", "<leader>wd", "<C-w>c", { desc = "Delete window" })

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bb", "<cmd>edit #<cr>", { desc = "Switch to last buffer" })

-- Stay in indent mode on visual indent
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Move lines (Alt-j/k) — works on terminals that map Alt
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move line up" })
map("i", "<A-j>", "<Esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered on jumps / search
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search (centered)" })

-- Better paste in visual: don't overwrite register
map("x", "p", '"_dP', { desc = "Paste without yanking selection" })

-- Yank to system clipboard explicitly (clipboard=unnamedplus already does, but kept for muscle memory)
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- Diagnostics
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })

-- Quickfix / location list. <leader>xq and <leader>xl are owned by Trouble (see
-- plugins/trouble.lua); these here are just the next/prev navigation.
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprevious<cr>", { desc = "Prev quickfix" })
