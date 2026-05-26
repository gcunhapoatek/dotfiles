#!/usr/bin/env bash
# Real used% = (active + wired + compressor) / total.
# memory_pressure's "free percentage" excludes inactive/cached pages that
# macOS treats as reclaimable; it reads as "85% used" on a healthy system.
source "$CONFIG_DIR/colors.sh"

PCT="$(vm_stat 2>/dev/null | awk '
  /Pages free:/                  { gsub(/\./, "", $3); free=$3 }
  /Pages active:/                { gsub(/\./, "", $3); active=$3 }
  /Pages inactive:/              { gsub(/\./, "", $3); inactive=$3 }
  /Pages speculative:/           { gsub(/\./, "", $3); spec=$3 }
  /Pages wired down:/            { gsub(/\./, "", $4); wired=$4 }
  /Pages occupied by compressor:/ { gsub(/\./, "", $5); comp=$5 }
  END {
    total = free + active + inactive + spec + wired + comp
    used  = active + wired + comp
    if (total > 0) printf "%d", (used * 100) / total
  }')"
[ -z "$PCT" ] && exit 0

case "$PCT" in
  ''|[0-9]|[1-5][0-9]) COLOR=$GREEN ;;
  [6-7][0-9])          COLOR=$YELLOW ;;
  [8][0-9])            COLOR=$PEACH ;;
  *)                   COLOR=$RED ;;
esac

sketchybar --set "$NAME" icon="󰍛" icon.color="$COLOR" label="${PCT}%"
