#!/usr/bin/env bash
# Global SessionEnd hook. Prunes the Claude Code storage that the built-in
# `cleanupPeriodDays` (settings.json) does not cover. The built-in cleanup
# already handles file-history, backups, paste-cache, shell-snapshots, tasks,
# plans, debug logs and transcripts. This hook prunes:
#   - ~/.claude/telemetry/*                    older than 7 days
#   - ~/.claude/projects/*/handover/**/*.md     older than 7 days (curated, short-lived)
# Best-effort: failures swallowed so they never block session teardown.

set -uo pipefail

if [[ -d "$HOME/.claude/telemetry" ]]; then
  find "$HOME/.claude/telemetry" -mindepth 1 -maxdepth 1 -mtime +7 -exec rm -rf {} + 2>/dev/null || true
fi

# Handover files (live + consumed/) live under each per-project dir.
# Path match covers both projects/X/handover/foo.md and
# projects/X/handover/consumed/foo.md.
if [[ -d "$HOME/.claude/projects" ]]; then
  find "$HOME/.claude/projects" -type f -name '*.md' \
    -path '*/handover/*' -mtime +7 -delete 2>/dev/null || true
fi

exit 0
