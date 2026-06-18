---
name: plan-mode
description: Capture an approved plan into a curated per-project file so the next session can resume execution without losing intent. Trigger after `ExitPlanMode` is accepted by the user, when the user invokes `/plan-save`, says "save the plan", "persist this plan", or when a multi-step implementation is about to start. Also use to decide whether to enter plan mode in the first place.
---

# Plan mode

Two responsibilities:

1. **Decide when to enter plan mode.**
2. **Persist an approved plan** as a curated per-project artifact that survives session loss and is auto-surfaced on the next session.

The built-in `ExitPlanMode` tool only presents a plan to the user — the harness may also stash a copy under `~/.claude/plans/<slug>.md` with an arbitrary slug, but that file has no cwd, no status, and no structure. This skill writes the durable, project-scoped copy that `session-start.sh` reads on resume.

## When to enter plan mode

Enter plan mode (call `EnterPlanMode`) before implementation when **any** of these hold:

- The change touches **more than 2 files**, or crosses package/module boundaries.
- The work includes an **irreversible or shared-state step** (schema migration, force-push, mass rewrite, dependency removal, deploy, sending external messages).
- The user's request is **ambiguous** about scope, naming, or trade-offs — surface the choices instead of guessing.
- The task involves **new third-party config or API surface** where a wrong shape costs a full retry.

Skip plan mode for:

- Single-file edits with a clear ask.
- Bug fixes whose fix and test scope are already obvious.
- Pure read / explain / search tasks.

When entering plan mode, draft the plan against the **file structure below** so the persisted version is well-formed.

## Output path

After the user approves the plan in `ExitPlanMode`, immediately persist a curated copy:

```bash
slug="$(pwd | sed 's|[/.]|-|g')"
mkdir -p "$HOME/.claude/projects/$slug/plans"
stamp="$(date -u +%Y-%m-%dT%H%M%S)"
out="$HOME/.claude/projects/$slug/plans/$stamp.md"
```

One file per approved plan. Do not overwrite prior plans. If the user iterates on the plan in the same session, **append a new `## Revision <ts>` section to the existing file** rather than writing a new file — the revision history is part of the artifact.

**Lifecycle.**

- Active plans live at `plans/<ts>.md` (top level of the project's plans dir).
- When the work is done, move the file to `plans/completed/<ts>.md` and set `status: completed`. Same on abandonment (`status: abandoned`).
- `session-start.sh` surfaces only the most recent **active** plan (status not `completed`/`abandoned`, top-level only) with `mtime` ≤ 7 days. It walks candidates newest-first and skips `completed`/`abandoned`, so a newer finished plan never masks an older active one.
- **Long-running plans go dormant, not deleted.** The auto-surface window is `mtime` ≤ 7 days, but the prune window is 30 days — a plan untouched for 8–30 days stays on disk yet stops surfacing on resume. Appending a `## Status log` entry (any edit) refreshes `mtime` and keeps it in the surface window, so log progress on multi-week work to keep it live.
- `session-end-rotate.sh` prunes `plans/completed/*` after 7 days and `plans/*.md` (top-level) after 30 days. Stale active plans get cleaned up automatically.

## File structure

Use exactly these sections, in order. Skip a section only if it would be empty.

```markdown
---
cwd: <absolute path>
branch: <git branch at plan-approval time, or "(no git)">
created: <ISO timestamp UTC>
status: active            # active | completed | abandoned
last_handover: <path>     # optional — set if a handover precedes this plan
---

# Plan — <one-line title>

## Goal
<One sentence. The original ask.>

## Approach
<2–6 bullets. The strategy chosen and why this shape (mention rejected alternatives only when non-obvious).>

## Files
- `<path>` — <what changes, one line>

## Risks / irreversible steps
- <risk or step that needs user confirmation before execution; omit section if none>

## Test plan
- <how to verify: command, file:line, or one-sentence manual check>

## Status log
- <ISO ts> approved
- <ISO ts> <next state transition>
```

## Rules of restraint

- **Curate, do not transcribe.** A plan is the agreed shape of the work, not a chat replay.
- **One line per bullet.** If a thought needs a paragraph, it belongs in a comment or an issue.
- **Specifics over generalities.** Prefer `auth/login.ts:42 — fix off-by-one in expiry check` over `fix auth bug`.
- **Name irreversible steps explicitly** in the Risks section. The user should be able to scan it and spot anything that needs a second confirmation.
- **No filler.** Drop sections that would be empty rather than write "N/A".

## Procedure

1. Decide whether plan mode applies (see *When to enter plan mode*). If yes, call `EnterPlanMode` and draft the plan against the file structure.
2. Present the plan via `ExitPlanMode` for user approval.
3. **Immediately after approval**, write the curated copy to the per-project path above. Do not start implementation work before the file exists.
4. As work progresses, append entries to `## Status log` for non-trivial state transitions (e.g., "<ts> first file landed", "<ts> blocked on X").
5. On completion or abandonment: set `status:` in the frontmatter accordingly, then `mkdir -p "$HOME/.claude/projects/$slug/plans/completed"` and `mv` the file into `plans/completed/` (the dir may not exist yet — create it first or the `mv` fails).

## Reading a plan (next session)

The `session-start.sh` hook surfaces the most recent active plan for the current `cwd` (`additionalContext` block marked `--- BEGIN ACTIVE PLAN ---`).

When you see a plan in `additionalContext`:

- **First reply must include exactly one ack line** (the injected context spells it out):
  `Plan loaded: <path> (age: <age>) — resuming at "<next concrete step from the plan>"`
- Treat the plan's `## Approach` and `## Files` as the agreed scope. Do not silently expand it.
- If state has drifted (files moved, dependency renamed), update the plan **before** executing — flag the drift to the user.
- Append a `## Status log` entry when resuming, before doing other work.

## Cross-reference with handover

A plan and a handover are complementary:

- A **plan** is the agreed shape of the work — written **before** execution. Lives until the work ships or is abandoned.
- A **handover** is the curated session state — written at a **pause point**. Lives ≤ 48h, consumed on next session start.

When writing a handover during work that has an active plan, set `Active plan:` in the handover frontmatter so the next session loads both. When writing a plan that follows a previous handover, set `last_handover:` in the plan frontmatter. See [[handover]] for the handover skill.

## Anti-examples (do not write)

- "Plan: fix the thing." — no goal, no files, no test plan.
- A plan with no `## Risks` section for a migration / force-push / mass rewrite — that section is the whole point for risky work.
- "Status: active" left behind after the work merged. Move to `completed/` so it stops surfacing.
- Two near-identical plan files for the same task on the same day. If you iterate, append `## Revision <ts>` to the existing file.
