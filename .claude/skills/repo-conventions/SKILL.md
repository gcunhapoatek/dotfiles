---
name: repo-conventions
description: Style, naming, commit, and PR conventions used in this dotfiles repo. Triggers on phrases like "commit style", "branch naming", "PR title", "code style", "how should I name", "convention".
allowed-tools: Read Grep
---

# Repo conventions

## Commits

- **Conventional Commits**: `<type>(<optional scope>): <subject>`.
- Allowed types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, `style`, `revert`.
- Scope is the package name when the change is package-scoped: `nvim`, `zsh`, `aerospace`, `sketchybar`, `brewfile`, `makefile`, `claude`, etc.
- Subject ≤ 50 chars, imperative ("add", not "added"), lower-case, no trailing period.
- Body only when the *why* isn't obvious from the subject. Wrap at 72 chars.
- One logical change per commit. Don't fold formatting + a feature into one commit.

Recent examples that match the style:

```
improve snacks nvim dashboard
nvim: stylua-format remaining lua files
nvim: bump nvim-lspconfig and nvim-web-devicons pins
nvim: fix gitsigns hunk nav + drop deprecated undo_stage_hunk
```

(The repo also accepts a leading `<scope>:` shorthand without an explicit type prefix — see git log — but new commits should prefer the full Conventional Commits form.)

## Branches

- `kebab-case`, type-prefixed where it adds clarity:
  - `feat/sketchybar-battery`
  - `fix/nvim-treesitter-pin`
  - `chore/brewfile-bump`
- `main` is protected. Never force-push to it.

## Pull requests

- PR title mirrors the commit style: `<type>(<scope>): <subject>`. ≤ 70 chars.
- Description: 1–3 bullet summary of what changed and why, followed by a short test-plan checklist (what to verify after stowing).

## Code style

| Tool / file kind | Style                                                                                       |
| ---------------- | ------------------------------------------------------------------------------------------- |
| Bash scripts     | `#!/usr/bin/env bash` + `set -euo pipefail`, `[[ ]]` tests, quoted variables, no unguarded `rm -rf`. |
| Lua (nvim)       | `stylua`-formatted. Tabs for indent (matches existing files). One plugin spec per file under `lua/plugins/`. |
| TOML (aerospace) | 2-space indent, lower-case keys, comment new keybinds with what they do.                   |
| YAML / JSON     | 2-space indent.                                                                              |
| Markdown         | ATX headings (`#`, `##`), reference-style links allowed but inline preferred.               |

## Naming

- Stow package directories: lower-case, single word, matches the tool's command name (`nvim`, not `neovim`; `btop`, not `bpytop`).
- New `.claude/agents/` and `.claude/skills/` names: `kebab-case`, descriptive verb-noun (`code-reviewer`, `test-runner`, `project-architecture`).
- Hook scripts: `kebab-case.sh`, named after the event (`pre-tool-use.sh`).

## Where this skill stops

This skill covers conventions. For "where should X live?", use `project-architecture`. For "how is tool X currently wired?", use the matching `<tool>-edit` skill (e.g. `nvim-edit`, `zsh-edit`).
