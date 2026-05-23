---
name: session-learnings
description: Capture what was learned in the current session — corrections, repeated mistakes, validated successes, missing context — and propose durable updates to global CLAUDE.md, project CLAUDE.md, project skills, or auto-memory. Trigger at session end, or whenever the user types `/session-learnings`, `/learnings`, "capture learnings", or asks to "improve the setup from this session".
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

## Where each learning goes

Pick the narrowest scope that still captures the lesson:

| Learning shape                                                | Destination                                                       |
| ------------------------------------------------------------- | ----------------------------------------------------------------- |
| User personal preference, applies across all projects         | `~/.claude/CLAUDE.md` (append one-line rule under right section)  |
| Project convention, applies across all sessions in this repo  | `<project>/CLAUDE.md` (append; respect existing structure)        |
| Repeatable workflow for a tool used in this project           | `<project>/.claude/skills/<name>/SKILL.md` (new or extend)        |
| Stable fact about this project's state, goals, or stakeholders | Auto-memory: `~/.claude/projects/<project>/memory/` as `project_*.md` |
| Correction-shaped feedback for the user's collaboration style  | Auto-memory as `feedback_*.md`                                    |
| Pointer to external system (Linear, Slack channel, dashboard)  | Auto-memory as `reference_*.md`                                   |
| User role / expertise detail                                   | Auto-memory as `user_*.md`                                        |
| One-shot trivia that won't recur                              | **Drop it.** Not every observation is worth persisting.            |

When in doubt: narrower scope wins. A rule in project `CLAUDE.md` is cheaper to maintain than a global one that doesn't always apply.

## Procedure

1. **Collect candidates.** Produce a flat list with one line per candidate: `[scope] <one-line lesson>`. Don't write any files yet.
2. **De-duplicate against existing rules.** For each candidate, check the target file (or `MEMORY.md` index for auto-memory). If a near-duplicate exists, choose update-in-place or drop.
3. **Present to user.** Show the de-duplicated list with proposed destinations. Ask: "Apply all / pick / skip?"
4. **Apply accepted items.**
   - Edits to `CLAUDE.md` files: append under the most relevant existing section, one line, imperative.
   - Edits to skills: extend the existing `SKILL.md` or create a new one with the standard frontmatter.
   - Auto-memory: follow the format described in the auto memory section of the system prompt (frontmatter + body, link via `[[name]]`, update `MEMORY.md` index).
5. **Confirm.** Report what was written, where, and one-line summary per change.

## Rules of restraint

- Do **not** save code patterns, file paths, or anything derivable by reading the repo. The repo is the source of truth.
- Do **not** save anything already documented in an existing `CLAUDE.md` or skill.
- Do **not** save ephemeral session details (current todo state, today's PR list, what we did this hour).
- Do **not** auto-apply without showing the user the list first — even a "good" learning the user disagrees with is noise.
- Keep each appended rule to one line where possible. If it needs more, it probably belongs in a skill, not `CLAUDE.md`.

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
