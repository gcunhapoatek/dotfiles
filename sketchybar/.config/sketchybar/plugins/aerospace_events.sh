#!/usr/bin/env bash
# Bridge AeroSpace events to sketchybar via `aerospace subscribe` (0.21.0+),
# replacing per-event exec callbacks in aerospace.toml with one long-lived
# stream. Launched by aerospace.toml's after-startup-command; exits when the
# AeroSpace socket closes, so an AeroSpace restart starts exactly one fresh copy.
#
# Stream is JSON lines, e.g. {"_event":"focus-changed","windowId":75,...}.
# Only the event name matters, so match it with `case` instead of parsing JSON.
# AeroSpace has no window-closed event: a closed window's icon lingers in its
# pill until the next workspace switch / window detect (self-heals).

aerospace subscribe focused-workspace-changed window-detected focus-changed focused-monitor-changed |
  while IFS= read -r line; do
    case "$line" in
    *'"_event":"focused-workspace-changed"'* | *'"_event":"window-detected"'*)
      sketchybar --trigger aerospace_workspace_change
      ;;
    *'"_event":"focus-changed"'*)
      # Focus moves don't change the pills, so only the front_app items refresh.
      sketchybar --trigger front_app_refresh
      ;;
    *'"_event":"focused-monitor-changed"'*)
      # Second hot-plug detection path for plugins/monitor_watcher.sh.
      sketchybar --trigger monitor_change
      ;;
    esac
  done
