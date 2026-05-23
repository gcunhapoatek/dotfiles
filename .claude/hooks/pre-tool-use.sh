#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Blocks destructive commands before they run.
# Reads the hook event JSON on stdin, inspects tool_input.command.
# Exit 0  = allow.
# Exit 2  = block (stderr is shown to the user).

set -euo pipefail

# Stdin payload: { tool_name, tool_input: { command, description, ... }, ... }
payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"

# Empty command is harmless; let the tool itself reject it.
if [[ -z "$cmd" ]]; then
  exit 0
fi

block() {
  printf 'Blocked by .claude/hooks/pre-tool-use.sh: %s\n' "$1" >&2
  printf 'Command: %s\n' "$cmd" >&2
  exit 2
}

# rm -rf on /, $HOME, ~, or a top-level dir
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])rm[[:space:]]+(-[a-zA-Z]*[rRfF][a-zA-Z]*[[:space:]]+)+(/|~|\$HOME|\\\$HOME)([[:space:]]|$)'; then
  block "rm -rf against root or home directory"
fi

# Fork bomb
if printf '%s' "$cmd" | grep -Eq ':\(\)\{:\|:&\};:'; then
  block "fork bomb pattern detected"
fi

# Filesystem destruction
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])mkfs([[:space:]]|\.)' ; then
  block "mkfs invocation"
fi
if printf '%s' "$cmd" | grep -Eq 'dd[[:space:]]+if=.*[[:space:]]+of=/dev/'; then
  block "dd writing to a device node"
fi

# Force-push to protected branches
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]]+([^&|;]*[[:space:]])?(-f|--force)([[:space:]]|=).*(main|master|release|production|prod)'; then
  block "force-push to a protected branch"
fi
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[[:space:]]+--force[[:space:]]+(origin[[:space:]]+)?(main|master|release|production|prod)([[:space:]]|$)'; then
  block "force-push to a protected branch"
fi

# DB drop
if printf '%s' "$cmd" | grep -Eq '(DROP[[:space:]]+DATABASE|DROP[[:space:]]+TABLE[[:space:]]+(users|accounts|orders))'; then
  block "destructive SQL on a sensitive table or database"
fi

# Writing to .env without explicit "--confirm" sentinel
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(>|>>|tee|printf|echo)[[:space:]].*\.env([[:space:]]|$)'; then
  if ! printf '%s' "$cmd" | grep -q -- '--confirm'; then
    block "writing to a .env file without --confirm marker"
  fi
fi

exit 0
