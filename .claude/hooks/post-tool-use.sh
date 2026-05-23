#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit|MultiEdit). Runs the formatter for the
# kinds of files this dotfiles repo actually contains. Never fails the tool
# call: formatter errors surface as non-blocking stderr.

set -euo pipefail

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')"

[[ -z "$file" ]] && exit 0
[[ ! -f "$file" ]] && exit 0

ext="${file##*.}"
has() { command -v "$1" >/dev/null 2>&1; }

run() {
	"$@" || printf 'post-tool-use.sh: %s reported issues for %s\n' "$1" "$file" >&2
}

case "$ext" in
sh | bash)
	has shfmt && run shfmt -w "$file"
	has bash && run bash -n "$file"
	;;
lua)
	has stylua && run stylua "$file"
	;;
json)
	if has jq; then
		jq empty "$file" >/dev/null 2>&1 ||
			printf 'post-tool-use.sh: invalid JSON in %s\n' "$file" >&2
	fi
	;;
toml)
	has taplo && run taplo fmt "$file"
	;;
*)
	: # no formatter wired up for this extension in this repo
	;;
esac

exit 0
