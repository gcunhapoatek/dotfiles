#!/usr/bin/env bash
# Global PostToolUse hook (matcher: Write|Edit). When a shell script was
# written or edited, syntax-checks it with its own dialect's parser (zsh -n,
# sh -n or bash -n — `bash -n` rejects valid zsh), then runs shellcheck at
# error severity (matches CI) for the dialects shellcheck understands.
# Non-blocking: reports issues via hookSpecificOutput.additionalContext on
# stdout (exit 0). PostToolUse at exit 0 parses stdout JSON; stderr is NOT fed
# to the model (only exit 2 does that), so additionalContext is the reliable
# channel for lint feedback that must reach Claude.

set -uo pipefail

payload="$(cat)"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"
[[ -z "$path" ]] && exit 0
[[ -f "$path" ]] || exit 0

dialect=""
case "$path" in
*.zsh) dialect="zsh" ;;
*.sh | *.bash) dialect="bash" ;;
esac
# A shebang overrides the extension.
read -r shebang <"$path" || true
case "$shebang" in
'#!'*[/\ ]zsh*) dialect="zsh" ;;
'#!'*[/\ ]bash* | '#!'*[/\ ]ksh*) dialect="bash" ;;
'#!'*[/\ ]sh | '#!'*[/\ ]sh\ * | '#!'*[/\ ]dash*) dialect="sh" ;;
esac
[[ -n "$dialect" ]] || exit 0

report() {
  jq -nc --arg c "$1" '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$c}}'
  exit 0
}

if ! err="$("$dialect" -n "$path" 2>&1)"; then
  report "${dialect} -n failed for ${path}:
${err}"
fi

if [[ "$dialect" != zsh ]] && command -v shellcheck >/dev/null 2>&1; then
  if ! err="$(shellcheck -S error -f gcc "$path" 2>&1)"; then
    report "shellcheck (error severity) failed for ${path}:
${err}"
  fi
fi

exit 0
