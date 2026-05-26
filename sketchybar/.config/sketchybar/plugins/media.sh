#!/usr/bin/env bash
# Polls now-playing via nowplaying-cli (macOS 26 deprecated the media_change event).
# Single CLI call: `get title artist` returns both, one per line.
source "$CONFIG_DIR/colors.sh"

if ! command -v nowplaying-cli >/dev/null 2>&1; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

TITLE=""
ARTIST=""
{
  IFS= read -r TITLE
  IFS= read -r ARTIST
} < <(nowplaying-cli get title artist 2>/dev/null)

if [ -z "$TITLE" ] || [ "$TITLE" = "null" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ]; then
  LABEL="$ARTIST — $TITLE"
else
  LABEL="$TITLE"
fi

sketchybar --set "$NAME" drawing=on \
  icon="󰎈" \
  icon.color=$MAUVE \
  label="$LABEL"
