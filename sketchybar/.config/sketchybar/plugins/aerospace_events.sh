#!/usr/bin/env bash
# Bridge AeroSpace events to sketchybar via `aerospace subscribe` (0.21.0+),
# replacing per-event exec callbacks in aerospace.toml with one long-lived
# stream. Launched by aerospace.toml's after-startup-command; exits when the
# AeroSpace socket closes, so an AeroSpace restart starts exactly one fresh copy.
#
# Stream is JSON lines, e.g. {"_event":"focus-changed","windowId":75,...}.
# Only the event name matters, so match it with `case` instead of parsing JSON.
# focus-changed refreshes the pills too: AeroSpace has no window-closed or
# window-moved event, and move-node-to-workspace / closing a window only move
# focus — without it the moved/closed window's icon lingers in its old pill.

aerospace subscribe focused-workspace-changed window-detected focus-changed focused-monitor-changed mode-changed |
  while IFS= read -r line; do
    case "$line" in
    *'"_event":"mode-changed"'*)
      # {"_event":"mode-changed","mode":"service"} — also sent once on connect.
      mode="${line#*\"mode\":\"}"
      mode="${mode%%\"*}"
      sketchybar --trigger aerospace_mode_change MODE="$mode"
      ;;
    *'"_event":"focused-workspace-changed"'* | *'"_event":"window-detected"'* | *'"_event":"focus-changed"'*)
      sketchybar --trigger aerospace_workspace_change
      ;;
    *'"_event":"focused-monitor-changed"'*)
      # Second hot-plug detection path for plugins/monitor_watcher.sh.
      sketchybar --trigger monitor_change
      ;;
    esac
  done
