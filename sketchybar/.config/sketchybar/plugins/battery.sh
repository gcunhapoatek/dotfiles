#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

PMSET="$(pmset -g batt 2>/dev/null)"
PERCENTAGE="$(printf '%s\n' "$PMSET" | grep -Eo '[0-9]+%' | head -n1 | tr -d '%')"
# Show the charging bolt only while actually charging, not whenever on AC.
# pmset reports the per-battery state as "...%; charging|charged|discharging;".
# "charged" (full on AC) falls through to the %-based 100% icon (󰁹 green).
case "$PMSET" in
*"; charging;"* | *"; finishing charge;"*) CHARGING=1 ;;
*) CHARGING= ;;
esac

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

case "$PERCENTAGE" in
100 | 9[0-9])
  ICON="󰁹"
  COLOR=$GREEN
  ;;
[6-8][0-9])
  ICON="󰂀"
  COLOR=$GREEN
  ;;
[3-5][0-9])
  ICON="󰁾"
  COLOR=$YELLOW
  ;;
[1-2][0-9])
  ICON="󰁻"
  COLOR=$PEACH
  ;;
[0-9])
  ICON="󰂃"
  COLOR=$RED
  ;;
*)
  ICON="󰂃"
  COLOR=$RED
  ;;
esac

if [ -n "$CHARGING" ]; then
  ICON="󰂄"
  COLOR=$TEAL
fi

sketchybar --set "$NAME" icon="$ICON" \
  icon.color="$COLOR" \
  label="${PERCENTAGE}%"
