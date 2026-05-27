#!/usr/bin/env bash
# Per-monitor front-app indicator with MRU state cache.
# $NAME = front_app.<mon>. Script runs for every front_app.* item on each
# front_app_switched / aerospace_workspace_change event:
#   1. Refresh cache from globally focused window (monitor, workspace, app).
#      Idempotent — multiple invocations for the same event write the same key.
#   2. Render this item's monitor from its (monitor, workspace) cache entry,
#      falling back to first window in the workspace if no entry exists or the
#      cached app no longer has a window there.
#
# Cache lives under $TMPDIR per-user; survives sketchybar reloads, clears on
# reboot. Bash 3.2 compatible.
source "$CONFIG_DIR/icon_map.sh"

STATE_DIR="/tmp/sketchybar-front-app-${USER}"
mkdir -p "$STATE_DIR"

# --- 1. Refresh cache from current global focus ---------------------------
FOCUSED=$(aerospace list-windows --focused --format '%{monitor-id}%{tab}%{workspace}%{tab}%{app-name}' 2>/dev/null)
if [ -n "$FOCUSED" ]; then
  IFS=$'\t' read -r FMON FWS FAPP <<<"$FOCUSED"
  if [ -n "$FMON" ] && [ -n "$FWS" ] && [ -n "$FAPP" ]; then
    printf '%s' "$FAPP" >"$STATE_DIR/mon$FMON-ws$FWS"
  fi
fi

# --- 2. Render this monitor -----------------------------------------------
MON="${NAME##*.}"
VIS=$(aerospace list-workspaces --monitor "$MON" --visible 2>/dev/null | head -n 1)
if [ -z "$VIS" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

APP=""
CACHE_FILE="$STATE_DIR/mon$MON-ws$VIS"
if [ -f "$CACHE_FILE" ]; then
  APP=$(cat "$CACHE_FILE" 2>/dev/null)
fi

# Verify cached app still has a window in the visible workspace.
if [ -n "$APP" ]; then
  HIT=$(aerospace list-windows --workspace "$VIS" --format '%{app-name}' 2>/dev/null | grep -Fx -- "$APP" | head -n 1)
  if [ -z "$HIT" ]; then
    APP=""
    rm -f "$CACHE_FILE"
  fi
fi

# Fallback: first window in workspace (tree order).
if [ -z "$APP" ]; then
  APP=$(aerospace list-windows --workspace "$VIS" --format '%{app-name}' 2>/dev/null | head -n 1)
fi

if [ -z "$APP" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

__icon_map "$APP"
sketchybar --set "$NAME" drawing=on icon="$icon_result" label="$APP"
