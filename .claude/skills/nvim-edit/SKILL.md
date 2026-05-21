---
name: nvim-edit
description: Workflow for editing or adding plugins under nvim/.config/nvim/. Enforces fetching upstream plugin docs before writing Lua, since plugin APIs (snacks.nvim, lazy.nvim, treesitter, bufferline, blink.cmp, mason-lspconfig 2.x) drift fast and training-data recall is unreliable. Trigger when the user asks to edit, add, remove, configure, or debug anything inside nvim/.config/nvim/, or mentions a plugin in that tree.
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
2. **Fetch upstream docs before writing.** Use `WebFetch` against the canonical URL from the table below. Do not skip — APIs change between releases and lazy.nvim pins commits. Note: some plugins (notably `blink.cmp`) have near-empty GitHub READMEs and host real docs on dedicated sites. Use the dedicated URL when listed.
3. **Check the lockfile.** `nvim/.config/nvim/lazy-lock.json` records the exact commit. If docs on `main` describe a newer API than the pinned commit, prefer the pinned version's behavior or update the lock explicitly.
4. **Check for keymap collisions.** Before adding a new `<leader>X` mapping, grep `lua/` for that exact key. Maps register at different times (`init.lua` startup → plugin `keys = {}` at lazy-load → snacks `init` autocmd at `VeryLazy`). Last writer wins; collisions are silent.
5. **Match existing style.** Plugin specs in `lua/plugins/` are one-file-per-plugin returning a table. Keep `opts = {}` declarative; avoid `config = function()` unless required.
6. **After editing**, mention the doc URL(s) consulted in your end-of-turn summary so the user can verify.

## Canonical doc URLs

| Plugin | Docs |
|--------|------|
| lazy.nvim | https://lazy.folke.io/ |
| snacks.nvim | https://github.com/folke/snacks.nvim — per-module: `https://github.com/folke/snacks.nvim/blob/main/docs/<module>.md` (e.g. `picker.md`, `explorer.md`, `notifier.md`) |
| bufferline.nvim | https://github.com/akinsho/bufferline.nvim |
| lualine.nvim | https://github.com/nvim-lualine/lualine.nvim |
| catppuccin | https://github.com/catppuccin/nvim |
| nvim-treesitter | https://github.com/nvim-treesitter/nvim-treesitter (this repo uses `branch = "main"`, which has a different API than `master`) |
| nvim-ts-autotag | https://github.com/windwp/nvim-ts-autotag |
| plenary.nvim | https://github.com/nvim-lua/plenary.nvim |
| nvim-lspconfig | https://github.com/neovim/nvim-lspconfig |
| mason.nvim | https://github.com/mason-org/mason.nvim |
| mason-lspconfig.nvim | https://github.com/mason-org/mason-lspconfig.nvim (2.x changes `automatic_enable` semantics — see below) |
| mason-tool-installer.nvim | https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim |
| conform.nvim | https://github.com/stevearc/conform.nvim |
| nvim-lint | https://github.com/mfussenegger/nvim-lint |
| blink.cmp | **Install**: https://cmp.saghen.dev/installation — **Config**: https://cmp.saghen.dev/configuration/general (GitHub README is near-empty) |
| which-key.nvim | https://github.com/folke/which-key.nvim |
| gitsigns.nvim | https://github.com/lewis6991/gitsigns.nvim |
| flash.nvim | https://github.com/folke/flash.nvim |
| mini.* | https://github.com/nvim-mini/mini.nvim (org rename: was `echasnovski/*`, now `nvim-mini/*`. Submodules: `nvim-mini/mini.pairs`, `nvim-mini/mini.icons`, etc.) |
| render-markdown.nvim | https://github.com/MeanderingProgrammer/render-markdown.nvim |

For plugins not listed: resolve the GitHub URL from the plugin spec in `lua/plugins/<name>.lua` (first arg of the returned table), then fetch its README. If the README is sparse, check for a `docs/` directory or a dedicated docs site linked from the project page.

## nvim 0.11+ LSP API (sharp edge — many stale tutorials online)

This repo runs nvim ≥ 0.11 and uses mason-lspconfig 2.x. The modern pattern:

```lua
-- Per-server config (replaces require('lspconfig')[srv].setup{...})
vim.lsp.config('lua_ls', { settings = { Lua = { ... } } })

-- Apply capabilities globally (e.g. from blink.cmp)
local caps = require('blink.cmp').get_lsp_capabilities()
vim.lsp.config('*', { capabilities = caps })

-- mason-lspconfig auto-enables installed servers via vim.lsp.enable()
require('mason-lspconfig').setup({
  ensure_installed = { 'lua_ls', 'vtsls', ... },
  automatic_enable = true,
})
```

**Do not write** `require('lspconfig')[srv].setup{...}` — deprecated. **Do not call** `vim.lsp.enable()` yourself when `automatic_enable = true`; mason-lspconfig handles it.

**Order matters**: call `vim.lsp.config()` for each server **before** `mason-lspconfig.setup({automatic_enable=true})`, otherwise per-server settings won't be applied when servers are enabled.

## blink.cmp v1 vs v2

v2 is the current `main` branch with **breaking changes**. README warns explicitly. This repo pins `version = '1.*'`. If you fetch v2 docs and apply them to a v1 install (or vice versa), the config will break silently.

## Tool-name translation

Same tool, different ids across registries. Don't cross-reference blindly:

| Concept | Mason package | LSP server id | Linter id (nvim-lint) | Formatter id (conform) |
|---------|---------------|---------------|------------------------|------------------------|
| golangci-lint | `golangci-lint` | — | `golangcilint` | — |
| eslint daemon | `eslint_d` | — | `eslint_d` | — |
| Lua LSP | `lua-language-server` | `lua_ls` | — | — |
| TypeScript LSP | `vtsls` | `vtsls` | — | — |
| Python LSP | `basedpyright` | `basedpyright` | — | — |
| Python lint/format | `ruff` | `ruff` (LSP) | (via LSP) | `ruff_format`, `ruff_organize_imports` |
| Bash LSP | `bash-language-server` | `bashls` | — | — |
| Shell lint | `shellcheck` | — | `shellcheck` | — |
| Shell format | `shfmt` | — | — | `shfmt` |

When wiring `mason-tool-installer` use the **mason package** name. When wiring `lint.linters_by_ft` use the **linter id**. mason-lspconfig translates between mason package and LSP id automatically.

## After/ftplugin path

Per-filetype overrides (indent, textwidth, etc.) live at `nvim/.config/nvim/after/ftplugin/<lang>.lua` — at the **runtime root**, NOT under `lua/`. Use `vim.bo.shiftwidth = ...` (buffer-local). Loaded automatically by nvim after default ftplugin runs.

## Snacks picker as LSP nav

When `snacks.nvim` is in the stack (it is here), prefer its LSP sources over raw `vim.lsp.buf.*` for navigation that benefits from a fuzzy list:

- `Snacks.picker.lsp_definitions()`
- `Snacks.picker.lsp_references()`
- `Snacks.picker.lsp_implementations()`
- `Snacks.picker.lsp_type_definitions()`
- `Snacks.picker.lsp_symbols()` (document)
- `Snacks.picker.lsp_workspace_symbols()`

Keep `vim.lsp.buf.*` for single-target actions (rename, code_action, hover, signature_help, declaration).

## Things easy to get wrong

- **snacks.nvim picker/explorer sources**: `hidden = true` and `ignored = true` are required project-wide (configs live under `.config/`). Do not regress this.
- **lazy.nvim spec shape**: `opts` merges deeply with plugin defaults; replacing a list inside `opts` requires the full list, not a partial. Use `opts_extend = { "path.to.list" }` to append rather than replace.
- **Keymaps**: existing convention uses `keys = { ... }` in the plugin spec (lazy-loaded) rather than `vim.keymap.set` in `init.lua`. Match this. Check for collisions before adding.
- **Adding a plugin**: `lua/plugins/<name>.lua` returning `{ "owner/repo", opts = {...} }` is enough — `lazy.lua` auto-imports the directory. Do not edit `lazy.lua` to register it.
- **conform `format_on_save` vs `format_after_save`**: `format_on_save` runs synchronously at `BufWritePre` (blocks save until done); `format_after_save` runs async at `BufWritePost`. Pick one. Don't enable both.
- **`conceallevel` and markdown plugins**: `render-markdown.nvim` / `markview.nvim` need `conceallevel ≥ 2` to substitute icons. An ftplugin/autocmd setting `conceallevel = 0` for markdown will silently break them.
- **Treesitter `main` vs `master`**: this repo uses `main`, which has no `opts.ensure_installed` / `opts.highlight` / `opts.indent`. Parsers install via `require('nvim-treesitter').install({...})`, highlight via `FileType` autocmd calling `vim.treesitter.start()`. See `plugins/treesitter.lua` header comment.

## Stow note

`nvim/` is a stow package — editing files here updates `~/.config/nvim/` via symlink. No restow needed for edits to existing files. New files (including new subdirectories like `after/ftplugin/`) inside an already-stowed dir are picked up automatically thanks to `--no-folding`.
