#!/usr/bin/env bash
# Global PreToolUse hook (matcher: Slack MCP send/draft/schedule tools).
# Policy: every Slack message MUST go out as a draft — direct send and
# schedule are hard-blocked. The draft tool is allowed, with a reminder to
# apply the humanize-text skill to the body first.
#
# Output schema (PreToolUse): permissionDecision "deny"|"allow" +
# additionalContext / permissionDecisionReason, wrapped by Claude Code in a
# system reminder next to the tool result.

set -euo pipefail

payload="$(cat)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"

case "$tool" in
*slack_send_message | *slack_schedule_message)
	reason="Blocked: Slack messages must always go out as a draft. Use mcp__claude_ai_Slack__slack_send_message_draft instead of ${tool} — never send or schedule directly. The user reviews and sends the draft themselves."
	jq -nc \
		--arg r "$reason" \
		'{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'
	exit 0
	;;
*slack_send_message_draft)
	msg="Outbound Slack draft via ${tool}. Apply the humanize-text skill to the message body first — cut AI tells, match tone to the reader (internal teammate vs manager/leadership). Draft only; the user reviews and sends it."
	jq -nc \
		--arg ctx "$msg" \
		'{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"allow", additionalContext:$ctx}}'
	exit 0
	;;
*)
	exit 0
	;;
esac
