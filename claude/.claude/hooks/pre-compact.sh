#!/usr/bin/env bash
# Global PreCompact hook. Fires immediately before Claude Code compacts the
# conversation. Injects an instruction telling Claude to invoke the handover
# skill first, so a curated handover file is written before the lossy summary
# replaces the live context. If an active plan exists for this cwd, also
# instructs Claude to append a Status log entry to it before the handover.
#
# Output: hookSpecificOutput.additionalContext is appended to the next model
# turn, so Claude sees the instruction in-context.

set -euo pipefail

payload="$(cat)"
trigger="$(printf '%s' "$payload" | jq -r '.trigger // "auto"')"

slug="$(pwd | sed 's|[/.]|-|g')"
handover_dir="$HOME/.claude/projects/$slug/handover"
plan_dir="$HOME/.claude/projects/$slug/plans"

active_plan=""
if [[ -d "$plan_dir" ]]; then
  candidate="$(find "$plan_dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | tail -n 1)"
  if [[ -n "$candidate" ]]; then
    st="$(grep -m1 -E '^status:[[:space:]]*' "$candidate" 2>/dev/null | sed -E 's/^status:[[:space:]]*//; s/[[:space:]]+$//')"
    case "$st" in
    completed | abandoned) ;;
    *) active_plan="$candidate" ;;
    esac
  fi
fi

msg="Context about to be compacted (trigger: ${trigger}). Compaction is lossy. Before doing anything else, invoke the handover skill to write a curated handover file to ${handover_dir}/<UTC-ISO>.md."
if [[ -n "$active_plan" ]]; then
  msg="${msg} An active plan exists at ${active_plan} — append a \`## Status log\` entry summarizing where execution stands, set the handover's \`Active plan:\` to this path, then write the handover. After that, you may continue or yield."
else
  msg="${msg} After that, you may continue or yield."
fi

jq -nc \
  --arg ctx "$msg" \
  '{hookSpecificOutput:{hookEventName:"PreCompact", additionalContext:$ctx}}'
