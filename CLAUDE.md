# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Every top-level directory (other than `.git`, `.github`, `.claude`, `scripts`) is a **stow package** that mirrors the target path structure relative to `$HOME`. Stowing a package creates symlinks inside `$HOME` pointing back into the repo. `.claude/` is project-local Claude Code config — not stowed into `~/.claude/`.

Primary languages: Bash (scripts + hooks), Lua (Neovim config), TOML (AeroSpace), YAML/JSON (everything else). Runtime: macOS workstation; Homebrew is the package manager for everything declared in `Brewfile`.

## Architecture rules

- **Stow packages.** Every top-level directory is a stow package. To add config for a new tool, create `<tool>/.config/<tool>/...` so the symlinked target under `$HOME/.config/<tool>/` is correct. Files that target `$HOME` directly (like `.zshrc`) live at the package root — see `zsh/` as the reference.
- **`--no-folding` is mandatory.** `.stowrc` enforces it so every file gets its own symlink. Don't write tooling that relies on a single symlinked parent directory.
- **`Makefile` is the dispatch.** It auto-discovers packages by listing top-level directories minus the `EXCLUDE` list (`.git`, `.github`, `.claude`, `scripts`). Adding a directory at the root automatically registers a stow package — only do that intentionally.
- **No secrets in the repo.** Per-machine identity and tokens go in `~/.gitconfig.local`, `~/.zshrc.local`, `~/.zprofile.local`. The tracked configs source these when they exist.
- **Where new content goes:**

| What                                          | Where                                                                       |
| --------------------------------------------- | --------------------------------------------------------------------------- |
| Config for a new CLI tool `foo`               | `foo/.config/foo/...`                                                       |
| A dotfile at `$HOME/.something`               | `<pkg>/.something`                                                          |
| A new homebrew dependency                     | New line in `Brewfile` (under the right comment block)                      |
| Claude Code subagent                          | `.claude/agents/<name>.md`                                                  |
| Claude Code skill                             | `.claude/skills/<name>/SKILL.md`                                            |
| Claude Code hook                              | `.claude/hooks/<name>.sh` (chmod +x; wire into `.claude/settings.json`)     |

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
| `.claude/**/settings*.json`  | `jq empty <file>`                                |
| `aerospace.toml`             | `aerospace reload-config` (when AeroSpace running)|
| `zsh/.zshrc`, `zsh/.zprofile`| `zsh -n <file>`                                  |

There is no traditional test suite; the `test-runner` skill under `.claude/skills/test-runner/SKILL.md` codifies the validation matrix.

## Definition of done

A change is done when **all** of these hold:

1. The relevant validation in the table above passes for every touched file.
2. `make check` runs clean.
3. No new TODO / FIXME / XXX comments have been added without a tracking note in the PR body.
4. No secrets (tokens, API keys, work hostnames) are committed. Secrets go in `*.local` overrides.
5. New top-level directories are intentional stow packages; otherwise they should not exist.
6. Hook scripts are executable (`chmod +x`) and reference `${CLAUDE_PROJECT_DIR}` (project) or `$HOME` (global), not absolute personal paths.
7. The commit message follows Conventional Commits (`<type>(<scope>): <subject>`). See [.claude/skills/repo-conventions/SKILL.md](.claude/skills/repo-conventions/SKILL.md).

## Repo expectations

- **Branches:** `kebab-case`, type-prefixed (`feat/`, `fix/`, `chore/`, `refactor/`). `main` is protected — never force-push to it.
- **Commits:** Conventional Commits (`feat(nvim): ...`). One logical change per commit. Subject ≤ 50 chars, imperative, lower-case, no trailing period.
- **PR titles:** mirror the commit style. ≤ 70 chars. The PR body holds the detail.
- **PR body:** 1–3 bullet summary of *what* and *why*, then a short test-plan checklist of what to verify after stowing.

## Editing rules

**Ground every config edit in upstream docs.** Before editing or adding to any package, fetch the relevant tool/plugin's current documentation via `WebFetch`. Do not rely on memory or training-data recall — config schemas, plugin APIs, and CLI flags drift between releases.

Tool-specific workflows live in `.claude/skills/<tool>-edit/SKILL.md` when the tool is non-trivial (`nvim-edit`, `aerospace-edit`, `sketchybar-edit`, `zsh-edit`). For tools without a dedicated skill, resolve the doc URL from the upstream repo/site and fetch before writing.

**When adding a new tool/package:** confirm the tool isn't already in `Brewfile` and that its config path matches the target layout under `$HOME` before stowing.

## Not tracked (intentional)

- `gh/hosts.yml` — contains auth tokens; only `config.yml` is stowed
- `yazi/` — config being reworked, to be added back as a stow package when ready
- `.claude/settings.local.json` — personal Claude Code overrides (gitignored)

## Per-machine overrides

Secrets and identity are never committed. The tracked configs source these gitignored files when they exist:

| File                  | Purpose                                                |
| --------------------- | ------------------------------------------------------ |
| `~/.gitconfig.local`  | `[user]` block, `commit.gpgSign`, work `includeIf`     |
| `~/.zshrc.local`      | Private aliases, API keys, per-machine PATH            |
| `~/.zprofile.local`   | Login-shell secrets                                    |

## Nvim config layout

`nvim/.config/nvim/` follows lazy.nvim conventions:

- `init.lua` — loads `config.options` then `config.lazy`
- `lua/config/lazy.lua` — lazy.nvim bootstrap, imports all `lua/plugins/*.lua`
- `lua/plugins/` — one file per plugin or plugin group

Active plugins: **snacks.nvim** (explorer + picker + notifier + many extras), **bufferline**, **lualine**, **catppuccin**, **treesitter**, **plenary**.

The picker and explorer sources (`files`, `grep`, `smart`, `explorer`) all have `hidden = true` and `ignored = true` — essential since all configs live under `.config/` which would otherwise be excluded.
