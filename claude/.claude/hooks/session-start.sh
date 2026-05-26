#!/usr/bin/env bash
# Global SessionStart hook. Emits a JSON envelope with branch, last commit,
# dirty file count, ahead/behind vs upstream, stash count, and cwd. Also
# surfaces the most recent handover file (if any, age <= 48h) for the
# current working directory so the session resumes with curated state.
#
# Consume-on-load: after surfacing, the handover file is moved to
# handover/consumed/ so it loads at most once. Consumed files are pruned by
# stop-rotate.sh after 7 days.

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

jq -nc \
	--arg ctx "$ctx" \
	'{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$ctx}}'
