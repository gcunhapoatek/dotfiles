#!/usr/bin/env bash
# Bridge `media-control stream` to sketchybar, replacing a 25s `get` poll
# (macOS 26 deprecated the built-in media_change event). Writes the current
# title/artist to a cache file, then fires media_update; plugins/media.sh
# renders from that cache, so a sketchybar reload repaints without a new query.
#
# Started by sketchybarrc on every load. The pidfile keeps it single-instance
# across reloads; as a child of the brew service it stops with sketchybar.

STATE="${TMPDIR:-/tmp}/sketchybar-media-${USER}"
PIDFILE="${TMPDIR:-/tmp}/sketchybar-media-stream-${USER}.pid"
US=$'\x1f' # ASCII unit separator: not IFS whitespace, so empty fields survive

if [ -r "$PIDFILE" ]; then
  OLD="$(cat "$PIDFILE" 2>/dev/null)"
  if [ -n "$OLD" ] && ps -p "$OLD" -o command= 2>/dev/null | grep -q 'media_stream\.sh'; then
    exit 0
  fi
fi
printf '%s' "$$" >"$PIDFILE"

publish() {
  printf '%s%s%s\n' "$1" "$US" "$2" >"$STATE.tmp" && mv -f "$STATE.tmp" "$STATE"
  sketchybar --trigger media_update
}

# --no-diff: every line carries the full payload ({} when nothing is playing).
# The outer loop restarts the stream if media-control's perl adapter dies.
while true; do
  media-control stream --no-diff --no-artwork 2>/dev/null |
    jq --unbuffered -r '.payload | "\(.title // "")\u001f\(.artist // "")"' 2>/dev/null |
    while IFS="$US" read -r TITLE ARTIST; do
      publish "$TITLE" "$ARTIST"
    done
  # Stream ended: clear rather than leave a stale title showing.
  publish "" ""
  sleep 5
done
