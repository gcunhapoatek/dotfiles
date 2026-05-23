---
name: project-architecture
description: Answers questions about this dotfiles repo's structure, stow-package layout, which directory new tool configs go into, and how packages map to $HOME. Triggers on phrases like "where should X live", "add a new tool", "how is this repo organized", "stow package", "what goes in $HOME".
allowed-tools: Read Grep Glob
---

# Project architecture (dotfiles)

This repo is a GNU Stow farm. Every top-level directory (other than the Makefile `EXCLUDE` list: `.git`, `.github`, `.claude`) is a **stow package**. Stowing a package creates symlinks inside `$HOME` that point back into the repo.

## Top-level layout

```
dotfiles/
├── <package>/             # one directory per tool, mirrors $HOME layout
│   └── .config/<tool>/    # config files for the tool
├── Brewfile               # every CLI/cask the configs depend on
├── Makefile               # auto-discovers packages; drives stow
├── .stowrc                # global stow flags (--no-folding, --verbose=1)
├── install.sh             # bootstrap entrypoint (= make install)
├── CLAUDE.md              # project memory
└── .claude/               # agents, skills, hooks, settings
```

## Where new content goes

| You want to add…                              | Put it at…                                                |
| --------------------------------------------- | --------------------------------------------------------- |
| Config for a new CLI tool `foo`               | `foo/.config/foo/...` (then `stow foo`)                   |
| A dotfile that lives at `$HOME/.something`    | `<pkg>/.something` (e.g. `zsh/.zshrc` for `$HOME/.zshrc`) |
| A new homebrew dependency                     | A new line in `Brewfile`                                  |
| A Claude Code subagent                        | `.claude/agents/<name>.md`                                |
| A Claude Code skill                           | `.claude/skills/<name>/SKILL.md`                          |
| A Claude Code hook script                     | `.claude/hooks/<name>.sh` (chmod +x; wire in settings)    |
| A per-machine secret / token                  | `~/.zshrc.local` / `~/.zprofile.local` / `~/.gitconfig.local` (NOT in this repo) |
| Heavy reference docs for this skill           | `.claude/skills/project-architecture/context.md` (see below) |

## Always-true rules

- New top-level directories automatically become stow packages — the `Makefile` discovers them. Don't introduce one unless that's what you want.
- `.stowrc` enables `--no-folding`, so every file gets its own symlink. Don't rely on whole-directory symlinks.
- Tracked configs source `*.local` files when present, never inline secrets.

## Deeper reference

For the full deeper dive (per-package details, Brewfile rationale, neovim plugin layout, hooks contract), see [context.md](context.md). Load it on demand — don't pull it into context by default.

## How to use this skill

When the user asks where something should live, name the exact path and the stow command that wires it. When they ask how an existing thing is wired, point at the file under `<pkg>/.config/<tool>/...` and the `$HOME` symlink it produces.
