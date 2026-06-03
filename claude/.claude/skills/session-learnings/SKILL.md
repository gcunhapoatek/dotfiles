---
name: session-learnings
description: Capture what was learned in the current session — corrections, repeated mistakes, validated successes, missing context, and how well the skills you invoked actually performed — then propose durable updates to global CLAUDE.md, project CLAUDE.md, project skills (including the ones used this session), or auto-memory. Trigger at session end, or whenever the user types `/session-learnings`, `/learnings`, "capture learnings", or asks to "improve the setup from this session".
---

# Session learnings

Goal: turn each session into a small, durable improvement to the setup. Every correction the user gave you, every approach they validated, every missing piece of project context that cost you a tool call — those are signals. Capture them so the next session doesn't repeat the loss.

## When to run

- At natural session end (user says "done", "thanks", "that's it", or the work is clearly complete).
- When user explicitly invokes the skill.
- After a sequence of corrections inside the same session (don't wait for the end; capture while fresh).

## Inputs to scan

Walk back through the conversation and collect:

1. **Corrections.** Anything the user said "no", "don't", "stop", "actually", "wrong" to. Quote the exchange (paraphrase OK).
2. **Validated non-obvious choices.** Approaches the user confirmed with "yes exactly", "good call", "keep doing that", or accepted without pushback when a different path was equally available.
3. **Repeated mistakes.** Same correction more than once, or a mistake that matches an existing memory you should have applied.
4. **Missing project context.** Cases where you had to run a discovery command (find, grep, ls) for something that should have been documented — file paths, conventions, command names, env requirements.
5. **Surprising successes.** A tool, flag, command, or workflow that worked unusually well and isn't obvious from the code.
6. **Skill-quality signals.** For each skill you invoked this session (scan the transcript for `Skill` tool calls — see step 0), ask: did it mislead you (named a file/flag/API that has moved)? Did it lack a step you had to discover yourself? Did it trigger when it shouldn't have, or fail to trigger when it should? Did its guidance contradict the live repo? Each is a fix to *that* skill.

## Where each learning goes

Pick the narrowest scope that still captures the lesson:

| Learning shape                                                | Destination                                                       |
| ------------------------------------------------------------- | ----------------------------------------------------------------- |
| User personal preference, applies across all projects         | `~/.claude/CLAUDE.md` (append one-line rule under right section)  |
| Project convention, applies across all sessions in this repo  | `<project>/CLAUDE.md` (append; respect existing structure)        |
| Repeatable workflow for a tool used in this project           | `<project>/.claude/skills/<name>/SKILL.md` (new or extend)        |
| A skill you *used* this session misled, lacked a step, or mis-triggered | That skill's `SKILL.md` — fix the body, or tune the `description` if it's a trigger problem. **Resolve the real source first** (see restraint rules): a stowed/global skill under `~/.claude/skills/` is a symlink into its dotfiles package — edit there, not a copy |
| Stable fact about this project's state, goals, or stakeholders | Auto-memory: `~/.claude/projects/<project>/memory/` as `project_*.md` |
| Correction-shaped feedback for the user's collaboration style  | Auto-memory as `feedback_*.md`                                    |
| Pointer to external system (Linear, Slack channel, dashboard)  | Auto-memory as `reference_*.md`                                   |
| User role / expertise detail                                   | Auto-memory as `user_*.md`                                        |
| One-shot trivia that won't recur                              | **Drop it.** Not every observation is worth persisting.            |

When in doubt: narrower scope wins. A rule in project `CLAUDE.md` is cheaper to maintain than a global one that doesn't always apply.

## Procedure

0. **Enumerate skills invoked.** Scan the transcript for `Skill` tool calls made this session. List them — they're the only skills eligible for skill-quality fixes (don't touch a skill you didn't use). If none were invoked, skip input #6.
1. **Collect candidates.** Produce a flat list with one line per candidate: `[scope] <one-line lesson>`. Don't write any files yet.
2. **De-duplicate against existing rules.** For each candidate, check the target file (or `MEMORY.md` index for auto-memory). If a near-duplicate exists, choose update-in-place or drop.
3. **Present to user.** Show the de-duplicated list with proposed destinations. Ask: "Apply all / pick / skip?"
4. **Apply accepted items.**
   - Edits to `CLAUDE.md` files: append under the most relevant existing section, one line, imperative.
   - Edits to skills: extend the existing `SKILL.md` or create a new one with the standard frontmatter.
   - Skill-quality fixes (input #6): correct the stale body, add the missing step, or tune the `description` for trigger problems. Resolve the real source file first (see restraint rules).
   - Auto-memory: follow the format described in the auto memory section of the system prompt (frontmatter + body, link via `[[name]]`, update `MEMORY.md` index).
5. **Confirm.** Report what was written, where, and one-line summary per change.

## Rules of restraint

- Do **not** save code patterns, file paths, or anything derivable by reading the repo. The repo is the source of truth.
- Do **not** save anything already documented in an existing `CLAUDE.md` or skill.
- Do **not** save ephemeral session details (current todo state, today's PR list, what we did this hour).
- Do **not** auto-apply without showing the user the list first — even a "good" learning the user disagrees with is noise.
- Keep each appended rule to one line where possible. If it needs more, it probably belongs in a skill, not `CLAUDE.md`.
- **Only edit a skill you actually invoked this session** (per step 0). Don't rewrite skills you merely read about or that weren't exercised.
- **Verify a skill-fix against the live repo before writing it.** If the skill named a file/flag/API that "moved", confirm the new value by reading the current code — don't swap in a value you only inferred from one failure. Skills are durable and shared; a wrong fix misleads every future session.
- **Don't rewrite a skill on a single data point.** One miss tunes; a pattern (same gap hit twice, or a clearly stale reference) rewrites. When unsure, propose a narrower note over a structural change.
- **Edit the skill's real source, not a symlink copy.** Project skills live at `<project>/.claude/skills/<name>/SKILL.md`. Global skills under `~/.claude/skills/<name>/` are usually per-file symlinks into a dotfiles package (resolve with `readlink -f` / `ls -l`) — edit the package source, since that's the tracked file. Editing through the symlink writes the same bytes but the *change is a git diff in that dotfiles repo*: surface it (which repo, needs commit + re-stow), don't present it as a local-only tweak.

## Anti-examples (do not save)

- "User asked me to read settings.json today" — ephemeral.
- "The pre-tool-use.sh hook lives at ~/.claude/hooks/pre-tool-use.sh" — derivable from `ls`.
- "User likes when I do good work" — vacuous.
- "Don't break things" — not actionable.

## Good examples

- *Feedback memory:* "User prefers two-space indent inside Lua tables, not stylua's default tab. Why: matches existing nvim config style. How to apply: when editing under `nvim/.config/nvim/`."
- *Global CLAUDE.md rule:* "Run `bash -n` on every shell script touched before declaring done."
- *Project CLAUDE.md rule:* "Hooks in `.claude/hooks/` must be `chmod +x` and use `${CLAUDE_PROJECT_DIR}` not absolute paths."
- *Project skill:* New `mcp-auth/SKILL.md` capturing the multi-step OAuth flow for a specific MCP server, after spending several tool calls figuring it out.
- *Skill-quality fix:* The `nvim-edit` skill pointed at `mason-lspconfig` 1.x setup, but the repo is on 2.x — confirmed by reading `lua/plugins/lsp.lua`, then corrected the skill's example. (Used the skill this session; verified against live code; clear stale reference.)
