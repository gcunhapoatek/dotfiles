#!/usr/bin/env bash
# Global Stop hook. Throttles to once per 24h via marker, then prunes
# unbounded Claude Code storage:
#   - ~/.claude/file-history/*       older than 14 days
#   - ~/.claude/backups/*             older than 14 days
#   - ~/.claude/paste-cache/*         older than 7 days
#   - ~/.claude/shell-snapshots/*     older than 7 days
#   - ~/.claude/telemetry/*           older than 7 days
#   - ~/.claude/tasks/*               older than 30 days
#   - ~/.claude/plans/*               older than 30 days
#   - ~/.claude/projects/*/handover/* older than 60 days (curated, keep longer)
# Best-effort: failures swallowed so they never block a Stop event.

set -uo pipefail

marker="$HOME/.claude/.last-rotate"
if [[ -f "$marker" ]] && [[ $(($(date +%s) - $(stat -f %m "$marker" 2>/dev/null || echo 0))) -lt 86400 ]]; then
	exit 0
fi

prune() {
	local dir="$1" days="$2"
	[[ -d "$dir" ]] || return 0
	find "$dir" -mindepth 1 -maxdepth 1 -mtime "+${days}" -exec rm -rf {} + 2>/dev/null || true
}

prune "$HOME/.claude/file-history" 14
prune "$HOME/.claude/backups" 14
prune "$HOME/.claude/paste-cache" 7
prune "$HOME/.claude/shell-snapshots" 7
prune "$HOME/.claude/telemetry" 7
prune "$HOME/.claude/tasks" 30
prune "$HOME/.claude/plans" 30

# Handover files live under each per-project dir. Walk them with one find call.
if [[ -d "$HOME/.claude/projects" ]]; then
	find "$HOME/.claude/projects" -mindepth 3 -maxdepth 3 -type f -name '*.md' \
		-path '*/handover/*' -mtime +60 -delete 2>/dev/null || true
fi

date +%s >"$marker"
exit 0
