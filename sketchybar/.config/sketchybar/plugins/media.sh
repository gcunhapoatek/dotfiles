#!/usr/bin/env bash
# Polls now-playing via media-control (macOS 26 deprecated the media_change
# event, and nowplaying-cli returns null there). `get` prints `null` when
# nothing is playing, otherwise a JSON object with title/artist/playing.
# Toggles media_sep together with this item so the separator never dangles.
source "$CONFIG_DIR/colors.sh"

hide() {
  sketchybar --set "$NAME" drawing=off --set media_sep drawing=off
  exit 0
}

if ! command -v media-control >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  hide
fi

# media-control spawns a perl adapter over private MediaRemote APIs, which can
# stall and would block sketchybar's script runner. Cap it via gtimeout/timeout
# when present; fall back to an unguarded call so a missing coreutils never
# breaks the item.
TIMEOUT="$(command -v gtimeout || command -v timeout || true)"
if [ -n "$TIMEOUT" ]; then
  MC=("$TIMEOUT" 2 media-control get --no-artwork)
else
  MC=(media-control get --no-artwork)
fi

TITLE=""
ARTIST=""
{
  IFS= read -r TITLE
  IFS= read -r ARTIST
} < <("${MC[@]}" 2>/dev/null | jq -r 'select(. != null) | (.title // ""), (.artist // "")' 2>/dev/null)

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
