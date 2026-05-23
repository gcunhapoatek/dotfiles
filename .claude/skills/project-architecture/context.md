# Architecture deep dive

On-demand reference. Load only when `SKILL.md` isn't enough — for example, when the question hinges on how `Makefile` discovers packages, how the neovim config splits across files, or what `--no-folding` actually changes.

## Stow mechanics

- `.stowrc` carries `--no-folding --verbose=1`. `--no-folding` forces stow to create per-file symlinks rather than collapsing whole directories. This matters because several tools (yazi, nvim, sketchybar) write runtime state (lockfiles, lazy-lock files, build artifacts) back into the same directory the config lives in. With folding, that runtime state would leak into the repo via the symlinked parent.
- The Makefile auto-discovers packages by listing top-level directories minus the `EXCLUDE` list (`.git`, `.github`, `.claude`). So creating a new directory at the repo root *is* the same as registering a new stow package.
- `make stow PKG=<pkg>` runs `stow <pkg>` against `$HOME`. `make unstow PKG=<pkg>` undoes it.
- `make check` is a dry-run: `stow -n` for every package + `brew bundle check`.

## Per-package conventions

- `zsh/` — files live at the package root (`.zshrc`, `.zprofile`) because the targets are `$HOME/.zshrc`, `$HOME/.zprofile`. There is no `.config/zsh/` subdir.
- `nvim/` — everything under `.config/nvim/` so the symlinked target is `$HOME/.config/nvim/`. The lazy.nvim layout: `init.lua` → `lua/config/lazy.lua` → all of `lua/plugins/*.lua`.
- `aerospace/`, `sketchybar/`, `btop/`, `eza/`, `bat/`, `cursor/`, `fastfetch/`, `ghostty/`, `lazygit/`, `spotify-player/` — `.config/<tool>/` layout.
- `gh/` — only `gh/.config/gh/config.yml` is tracked; `gh/.config/gh/hosts.yml` is gitignored (auth tokens).
- `git/` — `.config/git/` layout. The tracked `config` file does `[include] path = ~/.gitconfig.local` so identity stays per-machine.

## Brewfile contract

The `Brewfile` is the *source of truth* for what must be installed on a freshly-bootstrapped machine. The Makefile does not auto-discover Brewfile entries — every formula/cask added must be added explicitly. When `make install` runs, it does `brew bundle --file=Brewfile` before restowing.

When a tracked config gains a new dependency (e.g. zshrc starts sourcing `zoxide`), add the corresponding `brew` entry to `Brewfile`. The convention in this repo is to group the entry under the right comment block (shell experience / terminal tools / git stack / etc).

## Per-machine overrides

`*.local` files are gitignored:

| File                  | Sourced by         | Purpose                                                  |
| --------------------- | ------------------ | -------------------------------------------------------- |
| `~/.gitconfig.local`  | `git/.config/git/config` via `[include] path = ...`     | `[user]` block, `commit.gpgSign`, work `includeIf`       |
| `~/.zshrc.local`      | `zsh/.zshrc`        | Private aliases, API keys, per-machine PATH              |
| `~/.zprofile.local`   | `zsh/.zprofile`     | Login-shell secrets                                      |

If you're editing a tracked config and you find yourself wanting to write a machine-specific value, route it through one of these instead.

## Editing rules (recap)

- Before editing a config, fetch upstream docs via `WebFetch`. Plugin/config schemas drift fast.
- For non-trivial tools, there's a dedicated `nvim-edit`, `aerospace-edit`, `sketchybar-edit`, `zsh-edit` skill that defines the workflow. Use it.
- After editing a hook script, re-run `chmod +x` and `bash -n` on it.

## .claude/

Holds the live config Claude Code reads in this repo: `settings.json`, `agents/`, `skills/`, `hooks/`. No plugin packaging — this repo is consumed via clone + stow, not via `/plugin install`.
