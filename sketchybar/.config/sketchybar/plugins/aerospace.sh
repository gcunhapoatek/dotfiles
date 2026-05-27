#!/usr/bin/env bash
# Master refresh for per-monitor workspace pills.
# For each monitor: query workspaces assigned to it, and the currently visible
# one. Highlight visible. One `aerospace list-windows --all` for icons (shared
# across monitors since each workspace belongs to one monitor). One chained
# `sketchybar --set` for all items.
# Subscribed to aerospace_workspace_change (driven by aerospace.toml callbacks:
# workspace switch, focus change, new window detection).
#
# Bash 3.2 (system default) compatible — indexed arrays only.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icon_map.sh"

MON_COUNT=$(aerospace list-monitors --count 2>/dev/null || echo 1)

# Build icon set per workspace from a single list-windows pass.
icons=()   # icons[1..9]
US=$'\x1f' # ASCII unit separator — dedup key delimiter
seen="${US}"
while IFS=$'\t' read -r WS APP; do
  if [ -z "$WS" ] || [ -z "$APP" ]; then
    continue
  fi
  case "$WS" in [1-9] | 10) ;; *) continue ;; esac
  key="${US}${WS}${US}${APP}${US}"
  case "$seen" in *"${key}"*) continue ;; esac
  seen="${seen}${WS}${US}${APP}${US}"
  __icon_map "$APP"
  icons[WS]="${icons[WS]:-}$icon_result"
done < <(aerospace list-windows --all --format '%{workspace}%{tab}%{app-name}' 2>/dev/null)

ARGS=()
for mon in $(seq 1 "$MON_COUNT"); do
  VISIBLE=$(aerospace list-workspaces --monitor "$mon" --visible 2>/dev/null | head -n 1)
  # Membership lookup: wrap in delimiters so '1' doesn't match '10' etc.
  WS_ON_MON_RAW=$(aerospace list-workspaces --monitor "$mon" 2>/dev/null)
  WS_ON_MON_DELIM=$'\n'"${WS_ON_MON_RAW}"$'\n'

  for sid in 1 2 3 4 5 6 7 8 9 10; do
    case "$WS_ON_MON_DELIM" in
    *$'\n'"$sid"$'\n'*) ;;
    *)
      ARGS+=(--set "space.$sid.$mon" drawing=off)
      continue
      ;;
    esac

    WS_ICONS="${icons[$sid]:-}"
    if [ "$sid" = "$VISIBLE" ]; then
      ARGS+=(--set "space.$sid.$mon"
        drawing=on
        background.drawing=on
        "background.color=$LAVENDER"
        "icon.color=$CRUST"
        "label.color=$CRUST"
        "label=$WS_ICONS")
    elif [ -n "$WS_ICONS" ]; then
      ARGS+=(--set "space.$sid.$mon"
        drawing=on
        background.drawing=off
        "icon.color=$SUBTEXT0"
        "label.color=$SUBTEXT0"
        "label=$WS_ICONS")
    else
      ARGS+=(--set "space.$sid.$mon" drawing=off)
    fi
  done
done

sketchybar "${ARGS[@]}"
