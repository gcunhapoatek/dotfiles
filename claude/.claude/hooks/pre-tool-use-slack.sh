#!/usr/bin/env bash
# Global PreToolUse hook (matcher: Slack MCP write tools).
# Policy: every Slack message MUST go out as a draft — direct send and
# schedule are hard-blocked. Anything else that writes to Slack (drafts,
# canvases, reactions) returns "ask" so the user sees the normal permission
# prompt; drafts also get a reminder to apply the humanize-text skill first.
#
# Output schema (PreToolUse): permissionDecision "deny"|"ask"|"allow" +
# permissionDecisionReason / additionalContext.

set -euo pipefail

payload="$(cat)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"

decide() {
  jq -nc --arg d "$1" --arg r "$2" --arg ctx "${3:-}" \
    '{hookSpecificOutput:({hookEventName:"PreToolUse", permissionDecision:$d, permissionDecisionReason:$r}
      + (if $ctx == "" then {} else {additionalContext:$ctx} end))}'
  exit 0
}

case "$tool" in
*slack_send_message | *slack_schedule_message)
  decide deny "Blocked: Slack messages must always go out as a draft. Use mcp__claude_ai_Slack__slack_send_message_draft instead of ${tool} — never send or schedule directly. The user reviews and sends the draft themselves."
  ;;
*slack_send_message_draft)
  decide ask "Slack draft — review before it lands in your drafts." \
    "Outbound Slack draft via ${tool}. Apply the humanize-text skill to the message body first — cut AI tells, match tone to the reader (internal teammate vs manager/leadership). Draft only; the user reviews and sends it."
  ;;
*slack_create_canvas | *slack_update_canvas | *slack_add_reaction)
  decide ask "${tool##*__} writes to Slack and is visible to others — confirm."
  ;;
*)
  exit 0
  ;;
esac
