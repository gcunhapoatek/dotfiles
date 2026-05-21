#!/usr/bin/env bash
# Highlight workspace item if it matches the focused AeroSpace workspace.
# $1 = workspace id this item represents
# $FOCUSED_WORKSPACE = passed by --trigger aerospace_workspace_change

source "$CONFIG_DIR/colors.sh"

if [ "$1" = "${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}" ]; then
  sketchybar --set "$NAME" background.drawing=on \
                           background.color=$LAVENDER \
                           label.color=$CRUST
else
  sketchybar --set "$NAME" background.drawing=off \
                           label.color=$SUBTEXT0
fi
