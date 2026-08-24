# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Every top-level directory (other than `.git`, `.github`, `scripts`) is a **stow package** that mirrors the target path structure relative to `$HOME`. Stowing a package creates symlinks inside `$HOME` pointing back into the repo.

Primary languages: Bash (scripts), Lua (Neovim config), TOML (AeroSpace), YAML/JSON (everything else). Runtime: macOS workstation; Homebrew is the package manager for everything declared in `Brewfile`.

## Architecture rules

- **Stow packages.** Every top-level directory is a stow package. To add config for a new tool, create `<tool>/.config/<tool>/...` so the symlinked target under `$HOME/.config/<tool>/` is correct. Files that target `$HOME` directly (like `.zshrc`) live at the package root — see `zsh/` as the reference.
- **`--no-folding` is mandatory.** `.stowrc` enforces it so every file gets its own symlink. Don't write tooling that relies on a single symlinked parent directory.
- **`Makefile` is the dispatch.** It auto-discovers packages by listing top-level directories minus the `EXCLUDE` list (`.git`, `.github`, `scripts`). Adding a directory at the root automatically registers a stow package — only do that intentionally.
- **No secrets in the repo.** Per-machine identity and tokens go in `~/.gitconfig.local`, `~/.zshrc.local`, `~/.zprofile.local`. The tracked configs source these when they exist.
- **Where new content goes:**

| What                                          | Where                                                                       |
| --------------------------------------------- | --------------------------------------------------------------------------- |
| Config for a new CLI tool `foo`               | `foo/.config/foo/...`                                                       |
| A dotfile at `$HOME/.something`               | `<pkg>/.something`                                                          |
| A new homebrew dependency                     | New line in `Brewfile` (under the right comment block)                      |

## Build & test

```bash
make install        # Full bootstrap: brew bundle + restow every package
make restow         # Re-symlink every package (idempotent)
make stow PKG=nvim  # Stow a single package
make unstow PKG=nvim
make check          # Dry-run: stow -n every package + brew bundle check (no changes)
make status         # Show discovered packages and target dir
make clean          # Unstow everything (removes all managed symlinks)
```

Per-file validation (run these on touched files before considering a change done):

| Touched file kind            | Validation                                       |
| ---------------------------- | ------------------------------------------------ |
| Bash script (`*.sh`)         | `bash -n <file>`                                 |
| Lua under `nvim/`            | `stylua <file>` (formats; exits non-zero on diff) |
| `Brewfile`                   | `brew bundle check --file=Brewfile`              |
| JSON config                  | `jq empty <file>`                                |
| `aerospace.toml`             | `aerospace reload-config` (when AeroSpace running)|
| `zsh/.zshrc`, `zsh/.zprofile`| `zsh -n <file>`                                  |

There is no traditional test suite; the table above is the validation matrix.

## Definition of done

A change is done when **all** of these hold:

1. The relevant validation in the table above passes for every touched file.
2. `make check` runs clean.
3. No new TODO / FIXME / XXX comments have been added without a tracking note in the PR body.
4. No secrets (tokens, API keys, work hostnames) are committed. Secrets go in `*.local` overrides.
5. New top-level directories are intentional stow packages; otherwise they should not exist.
6. The commit message follows Conventional Commits (`<type>(<scope>): <subject>`) — see **Repo expectations** below.

## Repo expectations

- **Branches:** `kebab-case`, type-prefixed (`feat/`, `fix/`, `chore/`, `refactor/`). `main` is protected — never force-push to it.
- **Commits:** Conventional Commits (`feat(nvim): ...`). One logical change per commit. Subject ≤ 50 chars, imperative, lower-case, no trailing period.
- **PR titles:** mirror the commit style. ≤ 70 chars. The PR body holds the detail.
- **PR body:** 1–3 bullet summary of *what* and *why*, then a short test-plan checklist of what to verify after stowing.

## Editing rules

**Ground every config edit in upstream docs.** Before editing or adding to any package, fetch the relevant tool/plugin's current documentation (e.g. via `WebFetch`). Do not rely on memory or training-data recall — config schemas, plugin APIs, and CLI flags drift between releases. This applies to every tool here: nvim plugins (snacks.nvim, lazy.nvim, treesitter, bufferline), AeroSpace, sketchybar, zsh integrations, git/delta, and anything new. Resolve the doc URL from the upstream repo/site and read it before writing.

**When adding a new tool/package:** confirm the tool isn't already in `Brewfile` and that its config path matches the target layout under `$HOME` before stowing.

## Not tracked (intentional)

- `gh/hosts.yml` — contains auth tokens; only `config.yml` is stowed
- `yazi/` — config being reworked, to be added back as a stow package when ready

## Per-machine overrides

Secrets and identity are never committed. The tracked configs source these gitignored files when they exist:

| File                  | Purpose                                                |
| --------------------- | ------------------------------------------------------ |
| `~/.gitconfig.local`  | `[user]` block, `commit.gpgSign`, work `includeIf`     |
| `~/.zshrc.local`      | Private aliases, API keys, per-machine PATH            |
| `~/.zprofile.local`   | Login-shell secrets                                    |

## Nvim config layout

`nvim/.config/nvim/` follows lazy.nvim conventions:

- `init.lua` — loads `config.options`, `config.keymaps`, `config.autocmds`, then `config.lazy`
- `lua/config/options.lua` — global `vim.opt` settings (leader keys live here too)
- `lua/config/keymaps.lua` — plugin-independent keymaps
- `lua/config/autocmds.lua` — plugin-independent autocmds, all under `user_*` augroups
- `lua/config/lazy.lua` — lazy.nvim bootstrap, imports all `lua/plugins/*.lua`
- `lua/plugins/` — one file per plugin or plugin group
- `after/ftplugin/` — per-filetype buffer options (indentation, textwidth)

Plugin groups, one file each under `lua/plugins/`:

| Area          | Plugins                                                             |
| ------------- | ------------------------------------------------------------------- |
| Core UI       | `snacks.nvim` (explorer, picker, notifier, terminal, dashboard, toggles, lazygit), `bufferline`, `lualine`, `catppuccin`, `mini.icons`, `which-key` |
| LSP / tooling | `nvim-lspconfig` + `mason` + `mason-lspconfig` + `mason-tool-installer`, `blink.cmp`, `conform` (format), `nvim-lint` (lint), `trouble` |
| Treesitter    | `nvim-treesitter` (**`main` branch** — different API from `master`), `-textobjects`, `-context`, `nvim-ts-autotag` |
| Editing       | `flash`, `mini.pairs`, `nvim-surround`, `gitsigns`, `todo-comments`, `render-markdown` |

Conventions worth knowing before editing:

- **Float borders come from `vim.o.winborder`** (`config/options.lua`), not per-plugin `border` options. blink.cmp, mason, gitsigns previews and native LSP/diagnostic floats all inherit it — don't reintroduce per-plugin borders.
- **Keymaps are single-owner.** Where two plugins could claim a key, the loser carries a comment naming the winner (e.g. `]]`/`[[` → snacks.words, `<C-k>` → blink.cmp, `<leader>bo` → snacks.bufdelete). Grep for "owned by" before adding a binding.
- **`nvim-treesitter` is on `main`**: no `opts.ensure_installed`/`highlight`/`indent`, parsers via `require('nvim-treesitter').install{}`, highlighting via a `FileType` autocmd. Check `plugins/treesitter.lua`'s header comment before touching it.
- **`nvim-ts-autotag`'s `ft` list must stay a subset of the installed parsers** — it is treesitter-driven and silently inert otherwise.

The picker and explorer sources (`files`, `grep`, `smart`, `explorer`) all have `hidden = true` and `ignored = true` — essential since all configs live under `.config/` which would otherwise be excluded.
