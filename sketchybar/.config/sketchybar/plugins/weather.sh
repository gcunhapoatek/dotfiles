#!/usr/bin/env bash
# Fetch current temperature + condition from wttr.in (auto-IP location).
# Cache last good result to /tmp so an offline poll keeps the previous reading.

source "$CONFIG_DIR/colors.sh"

CACHE="${TMPDIR:-/tmp}/sketchybar_weather.cache"

DATA="$(curl -fsS --max-time 4 'https://wttr.in/?format=%t|%C' 2>/dev/null)"

if [ -n "$DATA" ] && [[ "$DATA" == *"|"* ]]; then
  printf '%s' "$DATA" >"$CACHE"
elif [ -r "$CACHE" ]; then
  DATA="$(<"$CACHE")"
fi

if [ -z "$DATA" ]; then
  sketchybar --set "$NAME" icon="" icon.color=$OVERLAY0 label="--"
  exit 0
fi

TEMP="${DATA%%|*}"
COND="${DATA##*|}"
TEMP="${TEMP## }"
TEMP="${TEMP%% }"

case "$COND" in
*Sunny* | *Clear*)
  ICON="󰖙"
  COLOR=$YELLOW
  ;;
*Partly\ cloudy* | *Partly*)
  ICON="󰖕"
  COLOR=$SUBTEXT0
  ;;
*Cloudy* | *Overcast*)
  ICON="󰖐"
  COLOR=$OVERLAY2
  ;;
*Mist* | *Fog* | *Haze*)
  ICON="󰖑"
  COLOR=$OVERLAY1
  ;;
*Thunder*)
  ICON="󰖓"
  COLOR=$MAUVE
  ;;
*Snow* | *Blizzard* | *Sleet*)
  ICON="󰼶"
  COLOR=$SKY
  ;;
*Rain* | *Drizzle* | *Shower*)
  ICON="󰖖"
  COLOR=$BLUE
  ;;
*)
  ICON="󰖙"
  COLOR=$YELLOW
  ;;
esac

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$TEMP"
