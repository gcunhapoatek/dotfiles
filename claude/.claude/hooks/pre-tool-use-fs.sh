#!/usr/bin/env bash
# Global PreToolUse hook (matcher: Write|Edit|MultiEdit|NotebookEdit).
# Blocks edits to credential stores, private keys, env files, and any path
# nested under a known secrets directory. Read-side blocking lives in
# settings.json permissions.deny.

set -euo pipefail

payload="$(cat)"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
[[ -z "$path" ]] && exit 0

block() {
	printf 'Blocked by ~/.claude/hooks/pre-tool-use-fs.sh: %s\n' "$1" >&2
	printf 'Path: %s\n' "$path" >&2
	exit 2
}

# Credential stores (whole-dir).
case "$path" in
"$HOME"/.ssh/* | "$HOME"/.gnupg/* | "$HOME"/.aws/credentials* | "$HOME"/.aws/config | "$HOME"/.config/gh/hosts.yml | "$HOME"/.docker/config.json)
	block "edit to credential store"
	;;
"$HOME"/.netrc | */.netrc)
	block "edit to .netrc"
	;;
esac

# Private key file extensions / known names anywhere in the path.
case "$path" in
*.pem | *.key | *.p12 | *.pfx | *.asc | *id_rsa | *id_ed25519 | *id_ecdsa | *id_dsa)
	block "edit to private key file"
	;;
esac

# Nested-secret directories (parent path contains a secrets dir).
case "/$path/" in
*/secrets/* | */.secrets/* | */vault/* | */.vault/*)
	block "edit inside a secrets directory"
	;;
esac

# Allowlist: CI build-config env templates under .github/config are not secrets.
case "$path" in
*/.github/config/*.env)
	exit 0
	;;
esac

# Env / secret filenames.
base="${path##*/}"
case "$base" in
.env | .env.* | *.env | secrets.* | credentials.* | *.secret | *.secrets | *.kdbx)
	block "edit to env/secrets file"
	;;
esac

exit 0
