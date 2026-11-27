#!/usr/bin/env bash
# Fail if aerospace.toml's persistent-workspaces and sketchybar's WORKSPACES
# (workspaces.sh) disagree. They're kept static in both places on purpose —
# sketchybar must build its pills before AeroSpace answers at login.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOML="$DOTFILES_DIR/aerospace/.config/aerospace/aerospace.toml"
WORKSPACES_SH="$DOTFILES_DIR/sketchybar/.config/sketchybar/workspaces.sh"

# The array may span lines: take from the key to the first closing bracket.
toml_list="$(awk '/^persistent-workspaces[[:space:]]*=/,/\]/' "$TOML" |
  grep -o '"[^"]*"' | tr -d '"' | sort)"

# shellcheck source=../sketchybar/.config/sketchybar/workspaces.sh
source "$WORKSPACES_SH"
bar_list="$(printf '%s\n' $WORKSPACES | sort)"

if [ -z "$toml_list" ]; then
  echo "ERROR: no persistent-workspaces found in $TOML" >&2
  exit 1
fi

# Report each side's extras (set difference via padded word match).
only_in() {
  local from="$1" other=" ${2//$'\n'/ } " ws
  for ws in $from; do
    case "$other" in *" $ws "*) ;; *) printf '%s ' "$ws" ;; esac
  done
}

if [ "$toml_list" != "$bar_list" ]; then
  echo "persistent-workspaces and sketchybar WORKSPACES differ:" >&2
  echo "  only in aerospace.toml: $(only_in "$toml_list" "$bar_list")" >&2
  echo "  only in workspaces.sh:  $(only_in "$bar_list" "$toml_list")" >&2
  exit 1
fi
