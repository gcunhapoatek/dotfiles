---
name: plan-mode
description: Capture an approved plan into a curated per-project file so the next session can resume execution without losing intent. Trigger after `ExitPlanMode` is accepted by the user, when the user invokes `/plan-save`, says "save the plan", "persist this plan", or when a multi-step implementation is about to start. Also use to decide whether to enter plan mode in the first place.
---

# Plan mode

Two responsibilities:

1. **Decide when to enter plan mode.**
2. **Persist an approved plan** as a curated per-project artifact that survives session loss and is auto-surfaced on the next session.

The built-in `ExitPlanMode` tool only presents a plan to the user — the harness may also stash a copy under `~/.claude/plans/<slug>.md` with an arbitrary slug, but that file has no cwd and no structure. This skill writes the durable, project-scoped copy that `session-start.sh` reads on resume.

**No close ceremony.** Persist the plan, then just work. A plan auto-surfaces while it's recent and stops on its own — there is no required status-flip or move-to-completed step. See *Lifecycle* below.

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

One file per approved plan. Do not overwrite prior plans. If the user iterates on the plan in the same session, **edit the same file in place** — no new file, no special revision section.

## Lifecycle

Surfacing is automatic and time-based — no bookkeeping required:

- A plan **auto-surfaces** on session start for its cwd while `mtime` ≤ 7 days (most recent first).
- Past 7 days untouched, it goes **dormant** (stops surfacing) but stays on disk.
- `session-end-rotate.sh` **prunes** plans after 30 days. Nothing accumulates forever.
- Any edit (e.g. appending a `## Status log` line) refreshes `mtime` and keeps a multi-week plan in the surface window. Log progress on long-running work to keep it live.

**Stopping a finished plan early** (optional): a just-completed plan keeps surfacing for up to 7 days. If that nags you on resume, **delete the file**. There is no status flag — deletion is the only early-suppress.

## Persist-reliability warning

The persist step (writing the curated copy after approval) is instruction-driven — nothing forces it. The backstop: `post-tool-use-plan.sh` drops a `.pending` marker each time `ExitPlanMode` fires, and on the next session start `session-start.sh` checks whether any curated plan is newer than that marker. If none is, it surfaces a one-time **`REQUIRED ACK`** — the same mechanism plan/handover surfacing uses, so the loss reaches the user instead of sitting in passive context.

When you see it, your first reply must include the `Plan-persist check:` line. Two cases:

- **Approved and lost** — reconstruct the plan from the conversation and persist it per the file structure above before any implementation.
- **Rejected, or persist intentionally skipped** — ack with "no action" and continue.

The marker is consumed on load, so the next-session check prompts at most once per `ExitPlanMode`. The same-session window is covered too: a `Stop` hook (`stop-plan-check.sh`) checks the same marker when a turn ends and **blocks** with the same instruction if no curated plan was persisted — catching a loss within the live session, with the next-session check as backstop. It blocks at most once per distinct `ExitPlanMode` per session (a rejected plan → one block, ack, then stop), so it never loops.

## File structure

Use these sections, in order. Skip a section if it would be empty.

```markdown
---
cwd: <absolute path>
branch: <git branch at plan-approval time, or "(no git)">
created: <ISO timestamp UTC>
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
- <ISO ts> <optional progress note — refreshes mtime to keep the plan live>
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
4. (Optional) Append `## Status log` entries on multi-session work to leave breadcrumbs and refresh `mtime`.

## Reading a plan (next session)

The `session-start.sh` hook surfaces the most recent recent plan for the current `cwd` (`additionalContext` block marked `--- BEGIN ACTIVE PLAN ---`).

When you see a plan in `additionalContext`:

- **First reply must include exactly one ack line** (the injected context spells it out):
  `Plan loaded: <path> (age: <age>) — resuming at "<next concrete step from the plan>"`
- Treat the plan's `## Approach` and `## Files` as the agreed scope. Do not silently expand it.
- If state has drifted (files moved, dependency renamed), update the plan **before** executing — flag the drift to the user.
- If the surfaced plan is for work already finished, say so and offer to delete it.

## Cross-reference with handover

A plan and a handover are complementary:

- A **plan** is the agreed shape of the work — written **before** execution.
- A **handover** is the curated session state — written at a **pause point**. Lives ≤ 48h, consumed on next session start.

When writing a handover during work that has an active plan, set `Active plan:` in the handover frontmatter so the next session loads both. When writing a plan that follows a previous handover, set `last_handover:` in the plan frontmatter. See [[handover]] for the handover skill.

## Anti-examples (do not write)

- "Plan: fix the thing." — no goal, no files, no test plan.
- A plan with no `## Risks` section for a migration / force-push / mass rewrite — that section is the whole point for risky work.
- Two near-identical plan files for the same task on the same day. If you iterate, edit the existing file in place.
</content>
</invoke>
