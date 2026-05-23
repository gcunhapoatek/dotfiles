#!/usr/bin/env bash
# Global PreCompact hook. Fires immediately before Claude Code compacts the
# conversation. Injects an instruction telling Claude to invoke the handover
# skill first, so a curated handover file is written before the lossy summary
# replaces the live context.
#
# Output: hookSpecificOutput.additionalContext is appended to the next model
# turn, so Claude sees the instruction in-context.

set -euo pipefail

payload="$(cat)"
trigger="$(printf '%s' "$payload" | jq -r '.trigger // "auto"')"

slug="$(pwd | sed 's|[/.]|-|g')"
handover_dir="$HOME/.claude/projects/$slug/handover"

msg="Context about to be compacted (trigger: ${trigger}). Compaction is lossy. Before doing anything else, invoke the handover skill to write a curated handover file to ${handover_dir}/<UTC-ISO>.md. After that, you may continue or yield."

jq -nc \
	--arg ctx "$msg" \
	'{hookSpecificOutput:{hookEventName:"PreCompact", additionalContext:$ctx}}'
