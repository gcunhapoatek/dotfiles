#!/usr/bin/env bash
# Global Stop hook. Catches the SAME-SESSION variant of the plan-persist gap:
# post-tool-use-plan.sh drops a `.pending` marker when ExitPlanMode fires; if a
# turn ends with no curated plan file newer than that marker, an approved plan
# was likely never persisted. session-start.sh already catches this on the NEXT
# session — this hook closes the window within the live session.
#
# Uses decision:block so Claude must re-engage before the turn ends. No loop:
# the per-session `.pending.nagged.<id>` sentinel records the marker timestamp
# already nagged, so a given ExitPlanMode blocks at most once per session (a
# rejected-plan marker → one block, Claude acks, then stops normally). A later,
# distinct ExitPlanMode (newer marker ts) can nag again. The `.pending` marker
# is left intact so the next-session backstop still fires if never resolved.

set -uo pipefail

payload="$(cat)"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
sid="$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null || true)"
[[ -n "$cwd" ]] || exit 0

slug="$(printf '%s' "$cwd" | sed 's|[/.]|-|g')"
plan_dir="$HOME/.claude/projects/$slug/plans"
pending_file="$plan_dir/.pending"
[[ -f "$pending_file" ]] || exit 0

pend_ts="$(cat "$pending_file" 2>/dev/null || echo 0)"
pend_ts="${pend_ts//[^0-9]/}"
pend_ts="${pend_ts:-0}"

sid="$(printf '%s' "$sid" | tr -cd 'a-zA-Z0-9-')"
sid="${sid:-unknown}"
nagged_file="$plan_dir/.pending.nagged.$sid"
last_nag_ts="$(cat "$nagged_file" 2>/dev/null || echo 0)"
last_nag_ts="${last_nag_ts//[^0-9]/}"
last_nag_ts="${last_nag_ts:-0}"

newest_plan_mtime=0
while IFS= read -r f; do
	[[ -n "$f" ]] || continue
	m="$(stat -f %m "$f" 2>/dev/null || echo 0)"
	if ((m > newest_plan_mtime)); then newest_plan_mtime=$m; fi
done < <(find "$plan_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null)

if ((pend_ts > newest_plan_mtime)) && ((pend_ts != last_nag_ts)); then
	printf '%s' "$pend_ts" >"$nagged_file" 2>/dev/null || true
	reason="A plan was presented via ExitPlanMode this session but no curated plan file was persisted afterward. If it was APPROVED: persist it now per the plan-mode skill (write \$HOME/.claude/projects/<slug>/plans/<ts>.md) before ending the turn. If it was REJECTED or you intentionally skipped persisting, reply acknowledging that — you may then stop."
	jq -nc --arg r "$reason" '{decision:"block", reason:$r}'
fi

exit 0
