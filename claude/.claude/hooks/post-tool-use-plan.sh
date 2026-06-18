#!/usr/bin/env bash
# Global PostToolUse hook (matcher: ExitPlanMode). Fires after a plan is
# presented for approval. The persist step in the plan-mode skill is purely
# instruction-driven, so this hook injects a hard reminder to write the
# curated per-project copy BEFORE any implementation work begins — closing the
# "approved plan, never persisted, lost on next session" gap.
#
# Best-effort: if the plan was rejected, the reminder is harmless (it is
# conditioned on approval). Output schema (PostToolUse): additionalContext,
# surfaced to Claude next to the tool result.

set -uo pipefail

cat >/dev/null  # drain stdin; payload unused

msg="Plan presented via ExitPlanMode. If the user APPROVED it: before doing any implementation work, persist the curated per-project copy per the plan-mode skill — write \$HOME/.claude/projects/<slug>/plans/<ts>.md (slug = cwd with / and . replaced by -), status: active, using the skill's file structure. Do not start editing files until that plan file exists. If the user rejected or asked for changes, ignore this."

jq -nc \
  --arg ctx "$msg" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$ctx}}'

exit 0
