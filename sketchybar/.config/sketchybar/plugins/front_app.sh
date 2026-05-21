#!/usr/bin/env bash
# Update label with frontmost app name; icon via sketchybar-app-font ligature map.
# Initial paint has no $INFO; query via osascript fallback.
source "$CONFIG_DIR/icon_map.sh"

if [ "$SENDER" = "front_app_switched" ] && [ -n "$INFO" ]; then
  APP="$INFO"
else
  APP="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)"
fi

__icon_map "$APP"

sketchybar --set "$NAME" icon="$icon_result" label="$APP"
