#!/usr/bin/env bash
# Global SessionStart hook. Emits a JSON envelope with branch, last commit,
# dirty file count, ahead/behind vs upstream, stash count, and cwd. Also
# surfaces the most recent handover file (if any, age <= 14 days) for the
# current working directory so the session resumes with curated state.

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
slug="$(printf '%s' "$cwd" | sed 's|[/.]|-|g')"
handover_dir="$HOME/.claude/projects/$slug/handover"
if [[ -d "$handover_dir" ]]; then
	latest="$(find "$handover_dir" -maxdepth 1 -type f -name '*.md' -mtime -14 2>/dev/null | sort | tail -n 1)"
	if [[ -n "$latest" ]]; then
		body="$(cat "$latest" 2>/dev/null || true)"
		if [[ -n "$body" ]]; then
			ctx="${ctx}

Most recent handover for this cwd: ${latest}
Read it before starting work. Resume from \"Next concrete step\". Honor \"Don't redo\".

--- BEGIN HANDOVER ---
${body}
--- END HANDOVER ---"
		fi
	fi
fi

jq -nc \
	--arg ctx "$ctx" \
	'{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$ctx}}'
