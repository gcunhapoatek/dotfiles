#!/usr/bin/env bash
# Show current Wi-Fi SSID or disconnected state.
# macOS 14.4+ broke `networksetup -getairportnetwork` for non-root (returns
# "not associated"); `ipconfig getsummary` is the working non-sudo path.
# Since macOS 15.6 it prints `<redacted>` instead of the SSID unless the caller
# has Location Services permission (SketchyBar #616) — treat that as
# "connected, name unknown" and show the icon alone.

source "$CONFIG_DIR/colors.sh"

# Wi-Fi interface name is stable per boot, so resolve it once and cache. Avoids
# a `networksetup` spawn on every poll (every 30s). Cache clears on reboot.
IFACE_CACHE="${TMPDIR:-/tmp}/sketchybar-wifi-iface-${USER}"
IFACE=""
[ -r "$IFACE_CACHE" ] && IFACE="$(cat "$IFACE_CACHE" 2>/dev/null)"
if [ -z "$IFACE" ]; then
  IFACE="$(networksetup -listallhardwareports 2>/dev/null |
    awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}')"
  IFACE="${IFACE:-en0}"
  printf '%s' "$IFACE" >"$IFACE_CACHE"
fi

SSID="$(ipconfig getsummary "$IFACE" 2>/dev/null | awk -F' SSID : ' '/ SSID : / {print $2; exit}')"

if [ "$SSID" = "<redacted>" ]; then
  sketchybar --set "$NAME" icon="󰖩" \
    icon.color=$SAPPHIRE \
    label.drawing=off
elif [ -n "$SSID" ]; then
  sketchybar --set "$NAME" icon="󰖩" \
    icon.color=$SAPPHIRE \
    label.drawing=on \
    label="$SSID"
else
  sketchybar --set "$NAME" icon="󰖪" \
    icon.color=$OVERLAY0 \
    label.drawing=on \
    label="off"
fi
