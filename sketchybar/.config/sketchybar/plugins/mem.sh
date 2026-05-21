#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

FREE="$(memory_pressure 2>/dev/null | awk -F': ' '/System-wide memory free percentage/ {gsub(/%/,"",$2); print $2; exit}')"
[ -z "$FREE" ] && exit 0
USED=$((100 - FREE))

case "$USED" in
  ''|0|[0-9]|[1-5][0-9]) COLOR=$GREEN ;;
  [6-7][0-9])            COLOR=$YELLOW ;;
  [8][0-9])              COLOR=$PEACH ;;
  *)                     COLOR=$RED ;;
esac

sketchybar --set "$NAME" icon="󰍛" icon.color="$COLOR" label="${USED}%"
