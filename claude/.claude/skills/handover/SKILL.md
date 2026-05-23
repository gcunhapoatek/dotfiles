---
name: handover
description: Capture the current session into a curated handover file so the next session can resume without quality loss. Trigger when the user types `/handover`, `/session-handover`, "write handover", "save handover", "context filling up — handover", or when the PreCompact hook injects a handover instruction. Prefer running this before context compaction starts; compaction is lossy summarization, handover is curated state.
---

# Session handover

Goal: produce one Markdown file at session-pause time that lets the next session resume the work without re-reading the full transcript. Curated, structured, terse. Not a chat replay.

## When to run

- User invokes `/handover`, `/session-handover`, or asks to "save / write a handover".
- PreCompact hook fires — `additionalContext` will explicitly request a handover. Do it before responding to anything else.
- Natural pause point in a long session (feature done, blocker hit, switching tasks).

## Output path

Write to:

```
~/.claude/projects/<proj-slug>/handover/<YYYY-MM-DDTHHMMSS>.md
```

Where `<proj-slug>` is the current working directory with `/` and `.` replaced by `-`. For example, `pwd` of `/Users/gabrieldacunha/Developer/dotfiles` → `-Users-gabrieldacunha-Developer-dotfiles`. Derive with:

```bash
slug="$(pwd | sed 's|[/.]|-|g')"
mkdir -p "$HOME/.claude/projects/$slug/handover"
stamp="$(date -u +%Y-%m-%dT%H%M%S)"
out="$HOME/.claude/projects/$slug/handover/$stamp.md"
```

One file per handover. Do not overwrite prior handovers — they form a chronological record.

## File structure

Use exactly these sections, in this order. Skip a section only if it would be empty.

```markdown
# Handover — <ISO timestamp UTC>

cwd: <absolute path>
branch: <git branch or "(no git)">
last commit: <short sha + subject, or "-">

## Goal
<One sentence. The original ask that drove this session.>

## State
- done: <what shipped / merged / verified>
- partial: <what's started but not finished — name the file and line if relevant>
- not started: <what was scoped but untouched>

## Decisions and why
- <decision> — <one-line rationale; mention rejected alternative if non-obvious>

## Files touched
- `<path>` — <one-line purpose>

## Blockers / open questions
- <blocker or question; tag with @user if it needs the human>

## Next concrete step
<Exact command, file:line, or one-sentence action to resume at. The reader should be able to run this without thinking.>

## Don't redo
- <dead ends already explored — approach + why it failed>
```

## Rules of restraint

- **Curate, do not transcribe.** No chat replay. No verbatim code dumps (git diff has those).
- **Specifics over generalities.** Prefer `src/auth/login.ts:42 — token expiry check off by one` over `auth bug`.
- **One line per bullet.** If a thought needs a paragraph, it belongs in a code comment or an issue, not the handover.
- **Capture failed paths.** "Don't redo" is the most valuable section — it prevents the next session from re-running the same dead ends.
- **No filler.** Drop sections that would be empty rather than write "N/A".
- **No secrets.** If a path or value would be sensitive, name the concept, not the value.

## Procedure

1. Derive `<proj-slug>` and timestamp.
2. Collect: goal, state, decisions, touched files (`git status` + tools history), blockers, next step, dead ends.
3. Write the file in one shot. Do not loop on the user for approvals — the user invoked this expecting an artifact.
4. Confirm to the user: one line with the file path and a sentence-long summary of what was captured.

## Reading a handover (next session)

The SessionStart hook surfaces the most recent handover for the current cwd. When you see one in `additionalContext`:

- Read it before doing anything else.
- Treat "Next concrete step" as the default resume action unless the user overrides.
- Honor "Don't redo" — do not re-explore those paths.
- After the user confirms scope, you may delete the consumed handover or leave it as history (default: leave).

## Anti-examples (do not write)

- "Worked on the auth flow for a while." — vague, no resume value.
- "User asked about X then we discussed Y." — chat replay.
- "TODO: finish the thing." — no path, no condition.
- "Everything is fine." — say nothing instead.
