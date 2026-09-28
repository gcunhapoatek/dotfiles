local map = vim.keymap.set

-- Quicker escape
map("i", "jk", "<Esc>", { desc = "Escape insert mode" })
-- `<C-/>` in terminal mode belongs to the snacks terminal toggle (see
-- plugins/snacks.lua); use a double Esc to drop into normal mode instead.
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Escape terminal mode" })

-- Save / quit. `<leader>w` is the "window" prefix; save via `<C-s>` or `:w`.
map({ "n", "i", "v" }, "<C-s>", "<cmd>silent! write<cr><Esc>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>confirm quit<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>confirm qall<cr>", { desc = "Quit all" })

-- Clear search highlight
map({ "n", "s" }, "<Esc>", "<cmd>noh<cr><Esc>", { desc = "Escape and clear hlsearch" })

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

-- Buffer navigation. `<S-h>`/`<S-l>` and `[b`/`]b` are owned by bufferline
-- (plugins/bufferline.lua) so cycling follows the tab bar's order.
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

-- No `zz`-centering remaps on <C-d>/<C-u>/n/N: the extra recenter fights
-- snacks.scroll's smooth-scroll animation (plugins/snacks.lua).

-- Better paste in visual: don't overwrite register. Native `v_P` does this
-- without `"_dP`'s off-by-one when the selection ends at end of line.
map("x", "p", "P", { desc = "Paste without yanking selection" })

-- Yank to system clipboard explicitly (clipboard=unnamedplus already does, but kept for muscle memory)
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-- `]d`/`[d` (diagnostics) and `]q`/`[q` (quickfix) are nvim 0.11+ defaults
-- with count support; float-on-jump comes from vim.diagnostic.config({ jump =
-- { on_jump = ... } }) in plugins/lsp.lua. <leader>xq / <leader>xl are owned
-- by Trouble (plugins/trouble.lua).
