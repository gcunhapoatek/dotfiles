#!/usr/bin/env bash
# Global PreToolUse hook (matcher: Slack MCP send/draft/schedule tools).
# Does NOT block. Injects a reminder so the humanize-text skill is applied
# to the message body before it leaves. Allows the call and passes context.
#
# Output schema (PreToolUse): permissionDecision "allow" + additionalContext,
# wrapped by Claude Code in a system reminder next to the tool result.

set -euo pipefail

payload="$(cat)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"

# Only fire for the outbound Slack tools. Anything else: pass through silently.
case "$tool" in
*slack_send_message | *slack_send_message_draft | *slack_schedule_message) ;;
*) exit 0 ;;
esac

msg="Outbound Slack message via ${tool}. Before this send: apply the humanize-text skill to the message body — cut AI tells, match tone to the reader (internal teammate vs manager/leadership), and confirm the final text with the user first. Sending is outward-facing; do not fire without a go-ahead."

jq -nc \
	--arg ctx "$msg" \
	'{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"allow", additionalContext:$ctx}}'
