# Project skills

Per-tool editing workflows for this dotfiles repo. Each subdirectory is one skill (`<tool>-edit/SKILL.md`).

## Policy

- **One skill per non-trivial config.** Add a skill when a tool has many moving parts, fast-drifting APIs, or non-obvious conventions (e.g. `nvim` with its plugin ecosystem).
- **Skip thin configs.** Single-purpose dotfiles (one-line aliases, declarative toggles) don't need a skill — the general rule in `CLAUDE.md` already covers them.
- **Lazy growth.** Don't pre-create skills for every package. Add one when the absence is felt — e.g. you catch the model guessing at an API.

## Current skills

- `nvim-edit/` — editing `nvim/.config/nvim/`, plugin doc URLs, lazy.nvim/snacks pitfalls.

## How skills trigger

Skills auto-trigger when the model recognizes intent matching the `description:` frontmatter. Keep descriptions specific about *when* the skill applies (file paths, user phrasings) so triggering is reliable.
