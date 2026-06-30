#!/usr/bin/env bash
# Global PostToolUse hook (matcher: ExitPlanMode). Fires after a plan is
# presented for approval. Two jobs:
#
#   1. Inject a hard reminder to persist the curated per-project copy BEFORE
#      any implementation work begins (the persist step in the plan-mode skill
#      is instruction-driven, so this nudge closes the "approved plan, never
#      persisted, lost on next session" gap).
#   2. Drop a cwd-attributed `.pending` marker recording WHEN this fired. The
#      persist step itself is unenforceable from here (PostToolUse cannot write
#      the plan — it has no plan body, and cannot tell approval from rejection).
#      So instead of trusting the nudge, session-start.sh compares this marker
#      against the newest persisted plan: if no curated plan is newer than the
#      marker, it warns once that an approved plan may have been lost. A marker
#      left by a *rejected* plan yields one dismissible warning — acceptable,
#      and it self-clears (consume-on-load) on the next session start.
#
# Output schema (PostToolUse): additionalContext, surfaced next to the result.

set -uo pipefail

payload="$(cat)"  # PostToolUse stdin; carries .cwd

cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
if [[ -n "$cwd" ]]; then
  slug="$(printf '%s' "$cwd" | sed 's|[/.]|-|g')"
  plan_dir="$HOME/.claude/projects/$slug/plans"
  mkdir -p "$plan_dir" 2>/dev/null || true
  date +%s >"$plan_dir/.pending" 2>/dev/null || true
fi

msg="Plan presented via ExitPlanMode. If the user APPROVED it: before doing any implementation work, persist the curated per-project copy per the plan-mode skill — write \$HOME/.claude/projects/<slug>/plans/<ts>.md (slug = cwd with / and . replaced by -), using the skill's file structure. Do not start editing files until that plan file exists. If the user rejected or asked for changes, ignore this."

jq -nc \
  --arg ctx "$msg" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$ctx}}'

exit 0
