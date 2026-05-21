#!/usr/bin/env bash
# Show current Wi-Fi SSID or disconnected state.
# macOS 14.4+ deprecated `networksetup -getairportnetwork` SSID output for non-root;
# fall back to `ipconfig getsummary`.

source "$CONFIG_DIR/colors.sh"

IFACE="en0"

SSID="$(networksetup -getairportnetwork "$IFACE" 2>/dev/null | awk -F': ' '/Current Wi-Fi Network/ {print $2}')"

if [ -z "$SSID" ] || [ "$SSID" = "You are not associated with an AirPort network." ]; then
  SSID="$(ipconfig getsummary "$IFACE" 2>/dev/null | awk -F' SSID : ' '/ SSID : / {print $2; exit}')"
fi

if [ -n "$SSID" ]; then
  sketchybar --set "$NAME" icon="󰖩" \
                           icon.color=$SAPPHIRE \
                           label="$SSID"
else
  sketchybar --set "$NAME" icon="󰖪" \
                           icon.color=$OVERLAY0 \
                           label="off"
fi
