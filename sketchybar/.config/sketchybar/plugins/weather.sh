#!/usr/bin/env bash
# Fetch current temperature, condition, sunrise and sunset from wttr.in
# (auto-IP location). Cache last good result so an offline poll keeps the
# previous reading.

source "$CONFIG_DIR/colors.sh"

CACHE="${TMPDIR:-/tmp}/sketchybar_weather.cache"

DATA="$(curl -fsS --max-time 4 'https://wttr.in/?format=%t|%C|%S|%s' 2>/dev/null)"

if [ -n "$DATA" ] && [[ "$DATA" == *"|"* ]]; then
  printf '%s' "$DATA" >"$CACHE"
elif [ -r "$CACHE" ]; then
  DATA="$(<"$CACHE")"
fi

if [ -z "$DATA" ]; then
  sketchybar --set "$NAME" icon="󰖐" icon.color=$OVERLAY0 label="--"
  exit 0
fi

IFS='|' read -r TEMP COND SUNRISE SUNSET <<<"$DATA"
TEMP="${TEMP## }"
TEMP="${TEMP%% }"
TEMP="${TEMP#+}"

# wttr.in capitalises only the first word ("Patchy rain nearby"), so match
# lower-cased. Most specific first: "Light rain, mist" must read as rain.
COND="$(printf '%s' "$COND" | tr '[:upper:]' '[:lower:]')"

# Sunrise/sunset are in the location's local time, which auto-IP makes ours.
NOW="$(date +%H:%M:%S)"
NIGHT=
if [ -n "$SUNRISE" ] && [ -n "$SUNSET" ] && { [[ "$NOW" < "$SUNRISE" ]] || [[ "$NOW" > "$SUNSET" ]]; }; then
  NIGHT=1
fi

case "$COND" in
*thunder*)
  ICON="󰖓"
  COLOR=$MAUVE
  ;;
*snow* | *blizzard* | *sleet* | *ice*)
  ICON="󰼶"
  COLOR=$SKY
  ;;
*rain* | *drizzle* | *shower*)
  ICON="󰖖"
  COLOR=$BLUE
  ;;
*mist* | *fog* | *haze*)
  ICON="󰖑"
  COLOR=$OVERLAY1
  ;;
*partly*)
  ICON="󰖕"
  COLOR=$SUBTEXT0
  ;;
*cloudy* | *overcast*)
  ICON="󰖐"
  COLOR=$OVERLAY2
  ;;
*)
  if [ -n "$NIGHT" ]; then
    ICON="󰖔"
    COLOR=$LAVENDER
  else
    ICON="󰖙"
    COLOR=$YELLOW
  fi
  ;;
esac

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$TEMP"
