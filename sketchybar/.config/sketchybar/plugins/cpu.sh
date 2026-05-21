#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

CORES="$(sysctl -n hw.logicalcpu 2>/dev/null)"
[ -z "$CORES" ] && CORES=1

CPU="$(ps -A -o %cpu= | awk -v c="$CORES" '{s+=$1} END {printf "%d", s/c}')"

case "$CPU" in
  ''|0|[0-9]|[1-2][0-9]) COLOR=$GREEN ;;
  [3-5][0-9])            COLOR=$YELLOW ;;
  [6-7][0-9])            COLOR=$PEACH ;;
  *)                     COLOR=$RED ;;
esac

sketchybar --set "$NAME" icon="󰻟" icon.color="$COLOR" label="${CPU}%"
