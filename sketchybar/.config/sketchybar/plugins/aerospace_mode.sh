#!/usr/bin/env bash
# Show the AeroSpace binding mode while it isn't `main`. $MODE comes from
# aerospace_mode_change (plugins/aerospace_events.sh); it's unset on the forced
# update after a reload, which hides the pill until the next mode change.

if [ -z "${MODE:-}" ] || [ "$MODE" = "main" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

sketchybar --set "$NAME" drawing=on label="$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')"
