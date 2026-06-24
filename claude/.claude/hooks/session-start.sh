#!/usr/bin/env bash
# Global SessionStart hook. Emits a JSON envelope with branch, last commit,
# dirty file count, ahead/behind vs upstream, stash count, and cwd. Also
# surfaces, for the current cwd:
#   - the most recent handover file (age <= 48h), consume-on-load
#   - the most recent active plan file (age <= 7d), persistent
#
# Handover consume-on-load: after surfacing, the handover file is moved to
# handover/consumed/ so it loads at most once. Consumed files are pruned by
# session-end-rotate.sh after 7 days.
#
# Plans are NOT consumed on load. A plan surfaces while its mtime is <= 7 days,
# then goes dormant on its own; session-end-rotate.sh prunes it after 30 days.
# No close ceremony — delete the file to suppress a finished plan early.
#
# Also emits a persist-reliability warning: if ExitPlanMode fired (per the
# .pending marker from post-tool-use-plan.sh) but no curated plan was saved
# afterward, the approved plan was likely lost. See the bottom of this script.

set -euo pipefail

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(no git)')"
sha="$(git rev-parse --short HEAD 2>/dev/null || echo '-')"
subject="$(git log -1 --pretty=%s 2>/dev/null || echo '-')"
cwd="$(pwd)"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  stashes="$(git stash list 2>/dev/null | wc -l | tr -d ' ')"
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || echo '')"
  if [[ -n "$upstream" ]]; then
    ahead="$(git rev-list --count "${upstream}..HEAD" 2>/dev/null || echo 0)"
    behind="$(git rev-list --count "HEAD..${upstream}" 2>/dev/null || echo 0)"
    track="ahead:${ahead} behind:${behind}"
  else
    track="no-upstream"
  fi
  ctx="branch: ${branch} | last: ${sha} ${subject} | dirty: ${dirty} | ${track} | stashes: ${stashes} | cwd: ${cwd}"
else
  ctx="branch: ${branch} | last: ${sha} ${subject} | cwd: ${cwd}"
fi

# Surface most recent handover for this cwd (slug = cwd with / and . → -).
# Window: 48h. Older handovers are stale; user must request explicitly.
slug="$(printf '%s' "$cwd" | sed 's|[/.]|-|g')"
handover_dir="$HOME/.claude/projects/$slug/handover"
if [[ -d "$handover_dir" ]]; then
  latest="$(find "$handover_dir" -maxdepth 1 -type f -name '*.md' -mtime -2 2>/dev/null | sort | tail -n 1)"
  if [[ -n "$latest" ]]; then
    body="$(cat "$latest" 2>/dev/null || true)"
    if [[ -n "$body" ]]; then
      mtime_epoch="$(stat -f %m "$latest" 2>/dev/null || echo 0)"
      age_s=$(($(date +%s) - mtime_epoch))
      if ((age_s < 3600)); then
        age="$((age_s / 60))m"
      elif ((age_s < 86400)); then
        age="$((age_s / 3600))h"
      else
        age="$((age_s / 86400))d"
      fi

      # Consume-on-load: move into consumed/ so it surfaces at most once.
      # If mv fails (e.g. permissions), still surface but log the path as-is.
      mkdir -p "$handover_dir/consumed" 2>/dev/null || true
      consumed_path="$handover_dir/consumed/$(basename "$latest")"
      if mv "$latest" "$consumed_path" 2>/dev/null; then
        surfaced_path="$consumed_path"
      else
        surfaced_path="$latest"
      fi

      ctx="${ctx}

REQUIRED ACK: Handover loaded for this cwd (age: ${age}). First reply must include exactly one line:
  Handover loaded: ${surfaced_path} (age: ${age}) — resuming at \"<next concrete step from handover>\"
Then proceed. Honor \"Don't redo\". File moved to consumed/ — will not re-surface.

--- BEGIN HANDOVER (age: ${age}) ---
${body}
--- END HANDOVER ---"
    fi
  fi
fi

# Surface most recent active plan for this cwd. Window: 7d. To suppress an
# already-finished plan early, delete its file (there is no status flag).
# Plans are NOT consumed on load.
plan_dir="$HOME/.claude/projects/$slug/plans"
plan_latest=""
if [[ -d "$plan_dir" ]]; then
  plan_latest="$(find "$plan_dir" -maxdepth 1 -type f -name '*.md' -mtime -7 2>/dev/null | sort -r | head -n 1)"
fi
if [[ -n "$plan_latest" ]]; then
  plan_body="$(cat "$plan_latest" 2>/dev/null || true)"
  if [[ -n "$plan_body" ]]; then
    plan_mtime="$(stat -f %m "$plan_latest" 2>/dev/null || echo 0)"
    plan_age_s=$(($(date +%s) - plan_mtime))
    if ((plan_age_s < 3600)); then
      plan_age="$((plan_age_s / 60))m"
    elif ((plan_age_s < 86400)); then
      plan_age="$((plan_age_s / 3600))h"
    else
      plan_age="$((plan_age_s / 86400))d"
    fi

    ctx="${ctx}

REQUIRED ACK: Active plan loaded for this cwd (age: ${plan_age}). First reply must include exactly one line:
  Plan loaded: ${plan_latest} (age: ${plan_age}) — resuming at \"<next concrete step from plan>\"
Then proceed. Treat the plan's Approach + Files as agreed scope; flag drift before expanding. If the plan is for finished work, say so and offer to delete it.

--- BEGIN ACTIVE PLAN (age: ${plan_age}) ---
${plan_body}
--- END ACTIVE PLAN ---"
  fi
fi

# Persist-reliability check. post-tool-use-plan.sh drops a `.pending` marker
# (epoch) each time ExitPlanMode fires. If no curated plan file is newer than
# that marker, the approved plan was likely never persisted (lost) — surface a
# REQUIRED ACK (same mechanism as plan/handover) so the loss reaches the user
# instead of sitting in passive context. Consume-on-load: the marker is removed
# regardless, so a given ExitPlanMode prompts at most once.
pending_file="$plan_dir/.pending"
if [[ -f "$pending_file" ]]; then
  pend_ts="$(cat "$pending_file" 2>/dev/null || echo 0)"
  pend_ts="${pend_ts//[^0-9]/}"
  pend_ts="${pend_ts:-0}"
  rm -f "$pending_file" 2>/dev/null || true

  newest_plan_mtime=0
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    m="$(stat -f %m "$f" 2>/dev/null || echo 0)"
    if ((m > newest_plan_mtime)); then newest_plan_mtime=$m; fi
  done < <(find "$plan_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null)

  pend_age=$(($(date +%s) - pend_ts))
  if ((pend_ts > newest_plan_mtime)) && ((pend_age < 1209600)); then
    ctx="${ctx}

REQUIRED ACK: ExitPlanMode fired for this cwd but no curated plan was persisted afterward — an approved plan may have been lost. First reply must include exactly one line:
  Plan-persist check: <action> — where <action> is \"reconstructing the unsaved plan\" (if it was approved) or \"no action — plan was rejected or persist intentionally skipped\".
If reconstructing, rebuild the plan from this conversation and persist it per the plan-mode skill before any implementation work."
  fi
fi

jq -nc \
  --arg ctx "$ctx" \
  '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$ctx}}'
