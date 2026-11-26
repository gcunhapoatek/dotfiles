#!/usr/bin/env bash
# Global PreToolUse hook (matcher: Write|Edit|NotebookEdit).
# Blocks edits to credential stores, private keys, env/secret data files, the
# per-machine *.local overrides, and any path nested under a secrets directory.
# Read-side blocking lives in settings.json permissions.deny.
#
# Paths are checked both as given and canonicalized (`..` collapsed, symlinks
# in the existing prefix resolved), and compared lowercased because APFS is
# case-insensitive — otherwise `~/x/../.ssh/config` or `~/.SSH/config` slip by.

set -euo pipefail

payload="$(cat)"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
[[ -z "$path" ]] && exit 0

block() {
  printf 'Blocked by ~/.claude/hooks/pre-tool-use-fs.sh: %s\n' "$1" >&2
  printf 'Path: %s\n' "$path" >&2
  exit 2
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Collapse `.`/`..` lexically, then resolve symlinks on the longest existing
# prefix; the file itself may not exist yet (Write creates it).
canonical() {
  perl -MCwd=abs_path -e '
    my $p = shift;
    $p = "$ENV{PWD}/$p" unless $p =~ m{^/};
    my @parts;
    for (split m{/}, $p) {
      next if $_ eq "" || $_ eq ".";
      if ($_ eq "..") { pop @parts } else { push @parts, $_ }
    }
    my @rest;
    while (@parts) {
      my $prefix = "/" . join("/", @parts);
      if (-e $prefix) {
        my $real = abs_path($prefix);
        $real = "" if $real eq "/";
        print $real, map({ "/$_" } @rest);
        exit;
      }
      unshift @rest, pop @parts;
    }
    print @rest ? join("", map({ "/$_" } @rest)) : "/";
  ' "$1"
}

home="$(lower "${HOME%/}")"

check() {
  local p base
  p="$(lower "$1")"
  base="${p##*/}"

  # Credential stores and per-machine secret overrides.
  case "$p" in
  "$home"/.ssh/* | "$home"/.gnupg/* | "$home"/.aws/credentials* | "$home"/.aws/config | \
    "$home"/.config/gh/hosts.yml | "$home"/.docker/config.json | "$home"/.npmrc | "$home"/.kube/*)
    block "edit to credential store"
    ;;
  "$home"/.zshrc.local | "$home"/.zprofile.local | "$home"/.gitconfig.local)
    block "edit to per-machine secrets override"
    ;;
  */.netrc)
    block "edit to .netrc"
    ;;
  esac

  # Private key file extensions / known names.
  case "$base" in
  *.pem | *.key | *.p12 | *.pfx | *id_rsa* | *id_ed25519* | *id_ecdsa* | *id_dsa*)
    block "edit to private key file"
    ;;
  esac

  # Nested-secret directories.
  case "$p/" in
  */secrets/* | */.secrets/* | */.vault/*)
    block "edit inside a secrets directory"
    ;;
  esac

  # Allowlist: committed env templates and CI build-config env files.
  case "$p" in
  */.github/config/*.env) return 0 ;;
  esac
  case "$base" in
  .env.example | .env.sample | .env.template) return 0 ;;
  esac

  # Env / secret data files. Source files that merely mention secrets in
  # their name (secrets.ts, credentials.py) are fine.
  case "$base" in
  .env | .env.* | *.env | *.secret | *.secrets | *.kdbx)
    block "edit to env/secrets file"
    ;;
  secrets.* | credentials.*)
    case "${base##*.}" in
    json | yaml | yml | toml | env | ini | txt | xml) block "edit to secrets data file" ;;
    esac
    ;;
  esac
  return 0
}

check "$path"
check "$(canonical "$path")"
exit 0
