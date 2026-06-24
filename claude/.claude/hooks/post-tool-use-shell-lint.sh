#!/usr/bin/env bash
# Global PostToolUse hook (matcher: Write|Edit). When a shell script
# was written or edited, runs `bash -n` to surface syntax errors immediately.
# Non-blocking: reports issues via hookSpecificOutput.additionalContext on
# stdout (exit 0). PostToolUse at exit 0 parses stdout JSON; stderr is NOT fed
# to the model (only exit 2 does that), so additionalContext is the reliable
# channel for lint feedback that must reach Claude.

set -uo pipefail

payload="$(cat)"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"
[[ -z "$path" ]] && exit 0
[[ -f "$path" ]] || exit 0

is_shell=0
case "$path" in
*.sh | *.bash | *.zsh) is_shell=1 ;;
esac
if [[ $is_shell -eq 0 ]]; then
	read -r shebang <"$path" || true
	case "$shebang" in
	'#!'*/sh | '#!'*/bash | '#!'*/zsh | '#!'*/dash | '#!'*/ksh) is_shell=1 ;;
	'#!/usr/bin/env sh' | '#!/usr/bin/env bash' | '#!/usr/bin/env zsh' | '#!/usr/bin/env dash' | '#!/usr/bin/env ksh') is_shell=1 ;;
	esac
fi
[[ $is_shell -eq 1 ]] || exit 0

if ! err="$(bash -n "$path" 2>&1)"; then
	jq -nc \
		--arg c "bash -n failed for ${path}:
${err}" \
		'{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$c}}'
fi

exit 0
