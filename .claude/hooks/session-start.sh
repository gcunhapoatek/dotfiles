#!/usr/bin/env bash
# SessionStart hook. Emits branch + last-commit + tree status as JSON
# additionalContext. CLAUDE.md is already loaded by Claude Code; do not
# re-inject it.

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(no git)')"
sha="$(git rev-parse --short HEAD 2>/dev/null || echo '-')"
subject="$(git log -1 --pretty=%s 2>/dev/null || echo '-')"

if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
	tree='clean'
else
	tree='dirty'
fi

ctx="branch: ${branch} | last: ${sha} ${subject} | tree: ${tree}"

jq -nc \
	--arg ctx "$ctx" \
	'{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$ctx}}'
