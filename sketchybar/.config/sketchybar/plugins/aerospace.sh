#!/usr/bin/env bash
# Master refresh for all numeric workspace pills.
# One `aerospace list-windows --all` query → one chained `sketchybar --set`.
# Subscribed to aerospace_workspace_change (driven by aerospace.toml callbacks:
# workspace switch, focus change, new window detection).
#
# Bash 3.2 (system default) compatible — indexed arrays only.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icon_map.sh"

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

icons=() # icons[1..9]
# Tab-delimited so app names containing '|' or ':' don't break parsing/dedup.
US=$'\x1f' # ASCII unit separator — dedup key delimiter
seen="${US}"
while IFS=$'\t' read -r WS APP; do
  [ -z "$WS" ] || [ -z "$APP" ] && continue
  case "$WS" in [1-9]) ;; *) continue ;; esac
  key="${US}${WS}${US}${APP}${US}"
  case "$seen" in *"${key}"*) continue ;; esac
  seen="${seen}${WS}${US}${APP}${US}"
  __icon_map "$APP"
  icons[$WS]="${icons[$WS]:-}$icon_result"
done < <(aerospace list-windows --all --format '%{workspace}%{tab}%{app-name}' 2>/dev/null)

ARGS=()
for sid in 1 2 3 4 5 6 7 8 9; do
  WS_ICONS="${icons[$sid]:-}"
  if [ "$sid" = "$FOCUSED" ]; then
    ARGS+=(--set "space.$sid"
      drawing=on
      background.drawing=on
      background.color=$LAVENDER
      icon.color=$CRUST
      label.color=$CRUST
      label="$WS_ICONS")
  elif [ -n "$WS_ICONS" ]; then
    ARGS+=(--set "space.$sid"
      drawing=on
      background.drawing=off
      icon.color=$SUBTEXT0
      label.color=$SUBTEXT0
      label="$WS_ICONS")
  else
    ARGS+=(--set "space.$sid" drawing=off)
  fi
done

sketchybar "${ARGS[@]}"
