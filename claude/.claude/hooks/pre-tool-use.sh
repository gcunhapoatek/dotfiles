#!/usr/bin/env bash
# Global PreToolUse hook (matcher: Bash). Blocks:
#   - rm -rf against /, $HOME, ~, or the actual user home path
#   - classic fork bomb
#   - mkfs invocations
#   - dd writing to /dev
#   - force-push to protected branches (main/master/release/prod[uction])
#   - curl|wget piped directly into a shell interpreter
# Exits 2 (blocks tool call) and prints reason on stderr.

set -euo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[[ -z "$cmd" ]] && exit 0

block() {
	printf 'Blocked by ~/.claude/hooks/pre-tool-use.sh: %s\n' "$1" >&2
	printf 'Command: %s\n' "$cmd" >&2
	exit 2
}

# rm with recursive AND force flags targeting root or home. Handles combined
# (-rf) and separated (-r -f) flag forms in either order. Quotes are stripped
# by a normalized copy of the command for matching.
norm_cmd="$(printf '%s' "$cmd" | tr -d "\"'")"
home_esc="$(printf '%s' "$HOME" | sed 's/[\/.]/\\&/g')"
target_re="(/|~|\\\$HOME|\\\$\\{HOME\\}|${home_esc})([[:space:]/]|$)"

if printf '%s' "$norm_cmd" | grep -Eq "(^|[[:space:]])rm([[:space:]]+(-[a-zA-Z]+|--[[:space:]]))+[[:space:]]*${target_re}"; then
	has_r="$(printf '%s' "$norm_cmd" | grep -Eo '(^|[[:space:]])rm([[:space:]]+-[a-zA-Z]+)+' | grep -Eo '\-[a-zA-Z]+' | grep -E '[rR]' || true)"
	has_f="$(printf '%s' "$norm_cmd" | grep -Eo '(^|[[:space:]])rm([[:space:]]+-[a-zA-Z]+)+' | grep -Eo '\-[a-zA-Z]+' | grep -E '[fF]' || true)"
	if [[ -n "$has_r" && -n "$has_f" ]]; then
		block "rm -rf against root or home directory"
	fi
fi

if printf '%s' "$cmd" | grep -Eq ':[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*:[[:space:]]*\|[[:space:]]*:[[:space:]]*&[[:space:]]*\}[[:space:]]*;[[:space:]]*:'; then
	block "fork bomb pattern detected"
fi

if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])mkfs([[:space:]]|\.)'; then
	block "mkfs invocation"
fi

if printf '%s' "$cmd" | grep -Eq 'dd[[:space:]]+if=.*[[:space:]]+of=/dev/'; then
	block "dd writing to a device node"
fi

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push([[:space:]]|$)' &&
	printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(-f|--force(-with-lease|-if-includes)?)([[:space:]]|=|$)' &&
	printf '%s' "$cmd" | grep -Eq '(^|[[:space:]:/])(main|master|release|production|prod)([[:space:]:]|$)'; then
	block "force-push to a protected branch"
fi
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push([[:space:]]|$)' &&
	printf '%s' "$cmd" | grep -Eq '[[:space:]]\+(main|master|release|production|prod)([[:space:]:]|$)'; then
	block "force-push (+refspec) to a protected branch"
fi

# Curl/wget piped into a shell interpreter. Catches:
#   curl ... | sh
#   curl ... | bash -s
#   wget -qO- ... | sudo sh
if printf '%s' "$cmd" | grep -Eq '(curl|wget)[[:space:]][^|]*\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash|zsh|ksh|fish|dash)([[:space:]]|$|-)'; then
	block "curl/wget piped into a shell interpreter"
fi

exit 0
