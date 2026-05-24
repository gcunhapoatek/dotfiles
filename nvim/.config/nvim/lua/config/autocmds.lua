local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		-- vim.hl.on_yank deprecated on nvim 0.13-dev in favor of vim.hl.hl_op
		-- (removal scheduled 0.14). Prefer hl_op when available.
		local hl_fn = vim.hl.hl_op or vim.hl.on_yank
		hl_fn()
	end,
})

-- Restore cursor position when reopening file
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_loc"),
	callback = function(args)
		local exclude = { "gitcommit", "gitrebase", "svn", "hgcommit" }
		local buf = args.buf
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
			return
		end
		vim.b[buf].last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Auto-create parent directories on save
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("auto_create_dir"),
	callback = function(args)
		if args.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(args.match) or args.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- Trim trailing whitespace on save (except for some filetypes, and skip when
-- conform has a formatter configured for this buffer — conform already
-- handles trailing whitespace via the underlying formatter).
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup("trim_whitespace"),
	callback = function(args)
		local exclude = { "markdown", "diff", "gitcommit" }
		if vim.tbl_contains(exclude, vim.bo.filetype) then
			return
		end
		local ok, conform = pcall(require, "conform")
		if ok and #conform.list_formatters(args.buf) > 0 then
			return
		end
		local view = vim.fn.winsaveview()
		vim.cmd([[keepjumps %s/\s\+$//e]])
		vim.fn.winrestview(view)
	end,
})

-- Equalize splits when terminal window resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- Close certain filetypes with q
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"help",
		"lspinfo",
		"man",
		"notify",
		"qf",
		"query",
		"checkhealth",
		"fugitive",
		"git",
		"gitcommit",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"neotest-output",
		"neotest-summary",
		"neotest-output-panel",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
	end,
})

-- Spell + wrap for text-like buffers
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("wrap_spell"),
	pattern = { "gitcommit", "markdown", "text" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

-- Check for file changes when nvim regains focus / buffer is entered
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})
