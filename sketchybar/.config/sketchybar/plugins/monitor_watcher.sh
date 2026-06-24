#!/usr/bin/env bash
# Reload sketchybar when the monitor count changes so per-monitor items
# (space.*.$mon, front_app.$mon) are recreated for the new display layout.
#
# Subscribed to display_change (active-display switch) and monitor_change
# (AeroSpace on-focused-monitor-changed). Both fire often, so a reload is gated
# on the monitor count actually differing from the cached value — a routine
# focus switch between existing monitors is a no-op.
#
# Caveat: neither event is a true hardware connect/disconnect signal. Plugging a
# monitor without moving focus/mouse to it may not fire either event until you
# do; if pills look stale after a hot-plug, switch to the new monitor once (or
# run `sketchybar --reload`). Bash 3.2 compatible.
STATE="/tmp/sketchybar-mon-count-${USER}"

CUR=$(aerospace list-monitors --count 2>/dev/null || echo 1)
PREV=""
[ -f "$STATE" ] && PREV=$(cat "$STATE" 2>/dev/null)

if [ "$CUR" != "$PREV" ]; then
  printf '%s' "$CUR" >"$STATE"
  # Skip reload on the first run (empty PREV) — the config is already current
  # from the load that spawned this item; reloading would be redundant.
  if [ -n "$PREV" ]; then
    sketchybar --reload
  fi
fi
