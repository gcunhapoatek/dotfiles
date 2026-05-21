#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo '[0-9]+%' | head -n1 | tr -d '%')"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

case "$PERCENTAGE" in
  100|9[0-9]) ICON="󰁹"; COLOR=$GREEN ;;
  [6-8][0-9]) ICON="󰂀"; COLOR=$GREEN ;;
  [3-5][0-9]) ICON="󰁾"; COLOR=$YELLOW ;;
  [1-2][0-9]) ICON="󰁻"; COLOR=$PEACH ;;
  *)          ICON="󰂃"; COLOR=$RED ;;
esac

if [ -n "$CHARGING" ]; then
  ICON="󰂄"
  COLOR=$TEAL
fi

sketchybar --set "$NAME" icon="$ICON" \
                         icon.color="$COLOR" \
                         label="${PERCENTAGE}%"
