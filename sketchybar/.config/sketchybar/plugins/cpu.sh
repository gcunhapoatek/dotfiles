#!/usr/bin/env bash
# Instantaneous CPU usage via top's 2-sample delta. `ps -o %cpu` returns a
# minute-smoothed decaying average that masks bursts; top -l 2 -s 1 reports
# real per-second delta in the second sample.
source "$CONFIG_DIR/colors.sh"

IDLE="$(top -l 2 -n 0 -s 1 2>/dev/null |
  awk -F'[ ,%]+' '/^CPU usage/ { for (i=1;i<=NF;i++) if ($i=="idle") v=int($(i-1)) } END { print v }')"
[ -z "$IDLE" ] && exit 0

CPU=$((100 - IDLE))

case "$CPU" in
[0-9] | [1-2][0-9]) COLOR=$GREEN ;;
[3-5][0-9]) COLOR=$YELLOW ;;
[6-7][0-9]) COLOR=$PEACH ;;
*) COLOR=$RED ;;
esac

sketchybar --set "$NAME" icon="󰻟" icon.color="$COLOR" label="${CPU}%"
