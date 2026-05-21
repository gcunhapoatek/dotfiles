# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Every top-level directory is a **stow package** that mirrors the target path structure relative to `$HOME`. Stowing a package creates symlinks inside `$HOME` pointing back here.

## Common commands

```bash
make install        # Full bootstrap: brew bundle + restow everything
make restow         # Re-symlink every package (idempotent)
make stow PKG=nvim  # Stow a single package
make unstow PKG=nvim
make check          # Dry-run stow + brew bundle check (no changes made)
make status         # Show discovered packages and target dir
make clean          # Unstow everything (removes all managed symlinks)
```

`./install.sh` is equivalent to `make install` for machines without `make`.

## Adding a new tool

1. `mkdir -p newtool/.config/newtool`
2. `mv ~/.config/newtool/* newtool/.config/newtool/`
3. `stow newtool`
4. Commit.

For dotfiles that live directly in `$HOME` (like `.zshrc`), put them at the package root — see `zsh/` as the reference.

## Architecture

- **`.stowrc`** — carries `--no-folding` and `--verbose=1` globally. `--no-folding` means every file gets its own symlink rather than collapsing whole directories; this is critical because tools write runtime files into the same directories.
- **`Makefile`** — auto-discovers packages by listing all top-level directories minus `.git`/`.github`. Adding a directory automatically makes it a stow package.
- **`Brewfile`** — declares every formula/cask the configs depend on. Not managed by the Makefile auto-discovery.

## Per-machine overrides

Secrets and identity are never committed. The tracked configs source these gitignored files when they exist:

| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | `[user]` block, `commit.gpgSign`, work `includeIf` |
| `~/.zshrc.local` | Private aliases, API keys, per-machine PATH |
| `~/.zprofile.local` | Login-shell secrets |

## Nvim config layout

`nvim/.config/nvim/` follows lazy.nvim conventions:

- `init.lua` — loads `config.options` then `config.lazy`
- `lua/config/lazy.lua` — lazy.nvim bootstrap, imports all `lua/plugins/*.lua`
- `lua/plugins/` — one file per plugin or plugin group

Active plugins: **snacks.nvim** (explorer + picker + notifier + many extras), **bufferline**, **lualine**, **catppuccin**, **treesitter**, **plenary**.

The picker and explorer sources (`files`, `grep`, `smart`, `explorer`) all have `hidden = true` and `ignored = true` — essential since all configs live under `.config/` which would otherwise be excluded.

## Editing rules

**Ground every config edit in upstream docs.** Before editing or adding to any package in this repo, fetch the relevant tool/plugin's current documentation via `WebFetch`. Do not rely on memory or training-data recall — config schemas, plugin APIs, and CLI flags drift between releases.

Tool-specific workflows and canonical doc URLs live in `.claude/skills/<tool>-edit/SKILL.md` when the tool is non-trivial (e.g. `nvim-edit`). For tools without a dedicated skill, resolve the doc URL from the upstream repo/site and fetch before writing.

**When adding a new tool/package**: confirm the tool isn't already in `Brewfile` and that its config path matches the target layout under `$HOME` before stowing.

## Not tracked (intentional)

- `gh/hosts.yml` — contains auth tokens; only `config.yml` is stowed
- `yazi/` — config being reworked, to be added back as a stow package when ready
