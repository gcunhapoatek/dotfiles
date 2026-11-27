#!/usr/bin/env bash
# Renders now-playing from the cache written by plugins/media_stream.sh (a
# `media-control stream` bridge). Runs on media_update and on the initial /
# forced update after a reload. Toggles media_sep together with this item so
# the separator never dangles.
source "$CONFIG_DIR/colors.sh"

STATE="${TMPDIR:-/tmp}/sketchybar-media-${USER}"

hide() {
  sketchybar --set "$NAME" drawing=off --set media_sep drawing=off
  exit 0
}

TITLE=""
ARTIST=""
if [ -r "$STATE" ]; then
  IFS=$'\x1f' read -r TITLE ARTIST <"$STATE"
fi

if [ -z "$TITLE" ]; then
  hide
fi

if [ -n "$ARTIST" ]; then
  LABEL="$ARTIST — $TITLE"
else
  LABEL="$TITLE"
fi

sketchybar --set "$NAME" drawing=on \
  icon="󰎈" \
  icon.color=$MAUVE \
  label="$LABEL" \
  --set media_sep drawing=on
