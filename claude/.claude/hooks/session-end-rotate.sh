#!/usr/bin/env bash
# Global SessionEnd hook. Fires once when a session terminates, so it prunes
# unbounded Claude Code storage exactly once per session — no throttle marker
# needed (the old Stop-hook version ran on every turn and self-throttled to
# 24h via a marker file). Prunes:
#   - ~/.claude/file-history/*       older than 14 days
#   - ~/.claude/backups/*            older than 14 days
#   - ~/.claude/paste-cache/*        older than 7 days
#   - ~/.claude/shell-snapshots/*    older than 7 days
#   - ~/.claude/telemetry/*          older than 7 days
#   - ~/.claude/tasks/*              older than 30 days
#   - ~/.claude/projects/*/handover/**/*.md older than 7 days (curated, short-lived)
# Best-effort: failures swallowed so they never block session teardown.

set -uo pipefail

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

# Handover files (live + consumed/) live under each per-project dir.
# Path match covers both projects/X/handover/foo.md and
# projects/X/handover/consumed/foo.md.
if [[ -d "$HOME/.claude/projects" ]]; then
  find "$HOME/.claude/projects" -type f -name '*.md' \
    -path '*/handover/*' -mtime +7 -delete 2>/dev/null || true
fi

exit 0
