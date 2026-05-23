#!/usr/bin/env bash
# Global PostToolUse hook (matcher: Write|Edit|MultiEdit). When a shell script
# was written or edited, runs `bash -n` to surface syntax errors immediately.
# Non-blocking: reports issues via stderr so Claude sees them, but does not
# fail the tool call (exit 0 unconditionally — syntax issues are feedback, not
# violations).

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
	'#!'*sh | '#!'*bash | '#!'*zsh | '#!/usr/bin/env '*sh*) is_shell=1 ;;
	esac
fi
[[ $is_shell -eq 1 ]] || exit 0

if ! err="$(bash -n "$path" 2>&1)"; then
	printf 'bash -n failed for %s:\n%s\n' "$path" "$err" >&2
fi

exit 0
