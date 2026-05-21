---
name: nvim-edit
description: Workflow for editing or adding plugins under nvim/.config/nvim/. Enforces fetching upstream plugin docs before writing Lua, since plugin APIs (snacks.nvim, lazy.nvim, treesitter, bufferline) drift fast and training-data recall is unreliable. Trigger when the user asks to edit, add, remove, configure, or debug anything inside nvim/.config/nvim/, or mentions a plugin in that tree.
---

# nvim-edit

Goal: every change to `nvim/.config/nvim/` is grounded in current upstream docs, not memory.

## When to invoke

- Any Edit/Write touching `nvim/.config/nvim/**`
- Adding a new plugin file under `lua/plugins/`
- Changing keymaps, options, or plugin opts
- Debugging a broken nvim config

## Workflow

1. **Identify the plugin(s) involved.** Read the target file first. If unsure which plugin owns a symbol, grep `lua/plugins/` for the spec.
2. **Fetch upstream docs before writing.** Use `WebFetch` against the canonical URL from the table below. Do not skip — APIs change between releases and lazy.nvim pins commits.
3. **Check the lockfile.** `nvim/.config/nvim/lazy-lock.json` records the exact commit. If docs on `main` describe a newer API than the pinned commit, prefer the pinned version's behavior or update the lock explicitly.
4. **Match existing style.** Plugin specs in `lua/plugins/` are one-file-per-plugin returning a table. Keep `opts = {}` declarative; avoid `config = function()` unless required.
5. **After editing**, mention the doc URL(s) consulted in your end-of-turn summary so the user can verify.

## Canonical doc URLs

| Plugin | Docs |
|--------|------|
| lazy.nvim | https://lazy.folke.io/ |
| snacks.nvim | https://github.com/folke/snacks.nvim — per-module: `https://github.com/folke/snacks.nvim/blob/main/docs/<module>.md` (e.g. `picker.md`, `explorer.md`, `notifier.md`) |
| bufferline.nvim | https://github.com/akinsho/bufferline.nvim |
| lualine.nvim | https://github.com/nvim-lualine/lualine.nvim |
| catppuccin | https://github.com/catppuccin/nvim |
| nvim-treesitter | https://github.com/nvim-treesitter/nvim-treesitter |
| plenary.nvim | https://github.com/nvim-lua/plenary.nvim |

For plugins not listed: resolve the GitHub URL from the plugin spec in `lua/plugins/<name>.lua` (first arg of the returned table), then fetch its README.

## Things easy to get wrong

- **snacks.nvim picker/explorer sources**: `hidden = true` and `ignored = true` are required project-wide (configs live under `.config/`). Do not regress this.
- **lazy.nvim spec shape**: `opts` merges deeply with plugin defaults; replacing a list inside `opts` requires the full list, not a partial.
- **Keymaps**: existing convention uses `keys = { ... }` in the plugin spec (lazy-loaded) rather than `vim.keymap.set` in `init.lua`. Match this.
- **Adding a plugin**: `lua/plugins/<name>.lua` returning `{ "owner/repo", opts = {...} }` is enough — `lazy.lua` auto-imports the directory. Do not edit `lazy.lua` to register it.

## Stow note

`nvim/` is a stow package — editing files here updates `~/.config/nvim/` via symlink. No restow needed for edits to existing files. New files inside an already-stowed dir are picked up automatically thanks to `--no-folding`.
