#!/usr/bin/env bash
# Master refresh for per-monitor workspace pills.
# One `aerospace list-workspaces --all` gives each workspace's monitor and
# visibility, one `aerospace list-windows --all` gives the app icons, and one
# chained `sketchybar --set` updates every space.<ws>.<mon> item.
# Monitor index is %{monitor-appkit-nsscreen-screens-id} (NSScreen order) —
# the numbering sketchybar's `display=` uses. AeroSpace's %{monitor-id} is
# spatial (left-to-right) and disagrees when a secondary sits left of main.
# Subscribed to aerospace_workspace_change (fired by plugins/aerospace_events.sh
# on workspace switch, window detection and focus change).
#
# Bash 3.2 (system default) compatible — no associative arrays, so
# per-workspace state lives in dynamic variables: icons_<ws>, mon_<ws>, vis_<ws>.
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icon_map.sh"
source "$CONFIG_DIR/workspaces.sh"

MON_COUNT=$(aerospace list-monitors --count 2>/dev/null || echo 1)

# Only workspaces with a pill item; ad-hoc ones would --set nonexistent items.
is_tracked() {
  case " $WORKSPACES " in *" $1 "*) return 0 ;; esac
  return 1
}

# App icons per workspace, deduped per (workspace, app).
US=$'\x1f' # ASCII unit separator — dedup key delimiter
seen="${US}"
while IFS=$'\t' read -r WS APP; do
  if [ -z "$WS" ] || [ -z "$APP" ] || ! is_tracked "$WS"; then
    continue
  fi
  key="${US}${WS}${US}${APP}${US}"
  case "$seen" in *"${key}"*) continue ;; esac
  seen="${seen}${WS}${US}${APP}${US}"
  __icon_map "$APP"
  var="icons_$WS"
  printf -v "$var" '%s%s' "${!var:-}" "$icon_result"
done < <(aerospace list-windows --all --format '%{workspace}%{tab}%{app-name}' 2>/dev/null)

# Owning monitor + visibility per workspace.
while IFS=$'\t' read -r WS MON VIS; do
  is_tracked "$WS" || continue
  printf -v "mon_$WS" '%s' "$MON"
  printf -v "vis_$WS" '%s' "$VIS"
done < <(aerospace list-workspaces --all --format '%{workspace}%{tab}%{monitor-appkit-nsscreen-screens-id}%{tab}%{workspace-is-visible}' 2>/dev/null)

ARGS=()
for mon in $(seq 1 "$MON_COUNT"); do
  for sid in $WORKSPACES; do
    mon_var="mon_$sid"
    vis_var="vis_$sid"
    icons_var="icons_$sid"
    WS_ICONS="${!icons_var:-}"

    if [ "${!mon_var:-}" != "$mon" ]; then
      ARGS+=(--set "space.$sid.$mon" drawing=off)
    elif [ "${!vis_var:-}" = "true" ]; then
      ARGS+=(--set "space.$sid.$mon"
        drawing=on
        background.drawing=on
        "background.color=$LAVENDER"
        "icon.color=$CRUST"
        "label.color=$CRUST"
        "label=$WS_ICONS")
    elif [ -n "$WS_ICONS" ]; then
      ARGS+=(--set "space.$sid.$mon"
        drawing=on
        background.drawing=off
        "icon.color=$SUBTEXT0"
        "label.color=$SUBTEXT0"
        "label=$WS_ICONS")
    else
      ARGS+=(--set "space.$sid.$mon" drawing=off)
    fi
  done
done

sketchybar "${ARGS[@]}"
