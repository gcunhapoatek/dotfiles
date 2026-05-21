#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
fi

case "$VOLUME" in
  100|[6-9][0-9]) ICON="󰕾"; COLOR=$PEACH ;;
  [3-5][0-9])     ICON="󰖀"; COLOR=$PEACH ;;
  [1-9]|[1-2][0-9]) ICON="󰕿"; COLOR=$YELLOW ;;
  *)              ICON="󰖁"; COLOR=$OVERLAY0 ;;
esac

sketchybar --set "$NAME" icon="$ICON" \
                         icon.color="$COLOR" \
                         label="${VOLUME}%"
