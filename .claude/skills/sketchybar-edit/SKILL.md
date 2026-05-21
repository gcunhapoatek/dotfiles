---
name: sketchybar-edit
description: Workflow for editing the sketchybar package (sketchybar/.config/sketchybar/sketchybarrc and plugins/). Enforces fetching upstream docs before writing bar/item/event flags, marking plugins executable, validating bash syntax, and reloading the running daemon. Trigger when the user asks to edit, add, remove, configure, or debug anything inside sketchybar/.config/sketchybar/, mentions a sketchybar item/event/plugin, or wants to integrate sketchybar with AeroSpace, yabai, or any other macOS status-bar source.
---

# sketchybar-edit

Goal: every change to the `sketchybar/` package is grounded in current upstream docs, plugin scripts are executable with absolute paths, and the running daemon picks up the edit without a logout.

## When to invoke

- Any Edit/Write touching `sketchybar/.config/sketchybar/**`
- Adding a new plugin script under `plugins/`
- Changing bar geometry, defaults, item props, or event subscriptions
- Wiring a custom event (`--add event` + `--trigger` + `--subscribe`)
- Integrating sketchybar with AeroSpace workspaces (see also `aerospace-edit`)
- Debugging a missing item, stale label, or crashed daemon

## Workflow

1. **Identify the surface.** Bar-wide chrome → `sketchybar --bar ...`. Item defaults → `sketchybar --default ...`. Per-item props → `sketchybar --set <name> ...`. Reactivity → `--subscribe` (event-driven) or `update_freq=N` (polling). If unsure, read the existing `sketchybarrc` first.
2. **Fetch upstream docs before writing flags.** Use `WebFetch` against the canonical URL in the table below. Flag names and accepted values drift between releases — do not paste from memory.
3. **Plugins must be executable with absolute paths.** Every script under `plugins/` needs `chmod +x` (the upstream setup page calls this out explicitly). Reference scripts as `$PLUGIN_DIR/foo.sh` where `PLUGIN_DIR="$CONFIG_DIR/plugins"`. Never use relative paths — sketchybar's CWD is not the config dir.
4. **Use the right subscription model.** A script that needs to react to system state should `--subscribe` to a named event (`front_app_switched`, `volume_change`, `system_woke`, `power_source_change`, or a custom one). Only fall back to `update_freq=N` for things with no event (e.g. a clock).
5. **Custom events: define → trigger → subscribe.** `sketchybar --add event <name>` in `sketchybarrc`, `sketchybar --trigger <name> VAR=value` from the external source (AeroSpace `exec-on-workspace-change`, an LaunchAgent, etc.), `--subscribe <item> <event>` on every item that should react. The item's script reads `$VAR` and uses `$NAME` (the item) plus `$SENDER` (the event name).
6. **AeroSpace ≠ macOS Mission Control.** Do **not** use `--add space <name>` (a sketchybar primitive bound to macOS MC spaces, designed for yabai). Use `--add item space.<id>` plus a custom event from AeroSpace. The example `space.sh` shipped under `$(brew --prefix)/share/sketchybar/examples/plugins/` is yabai-flavored — ignore it for this repo.
7. **Validate bash.** `bash -n` every edited script and the `sketchybarrc` itself (it is a bash script). Parse errors leave the bar in its previous state on `--reload`, so they are silent.
8. **Reload the daemon, don't restart unless needed.** `sketchybar --reload` re-runs `sketchybarrc` in the existing process — fast, preserves event subscriptions. `brew services restart sketchybar` is only needed when the binary itself changes or the daemon is wedged.
9. **If a new binary is introduced** (e.g. a plugin calls a brew formula not yet listed), add it to `Brewfile`. The repo's contract is that `make install` brings up a fresh machine; a plugin referencing an uninstalled binary breaks that.
10. **After editing**, mention the doc URL(s) consulted in your end-of-turn summary.

## Canonical doc URLs

| Topic | Docs |
|-------|------|
| Setup overview | https://felixkratz.github.io/SketchyBar/setup |
| Bar appearance (`--bar`) | https://felixkratz.github.io/SketchyBar/config/bar |
| Item properties (`--set`, `--default`) | https://felixkratz.github.io/SketchyBar/config/items |
| Built-in components (space, alias, graph, slider) | https://felixkratz.github.io/SketchyBar/config/components |
| Events (built-in + custom, `--add event`, `--trigger`, `--subscribe`) | https://felixkratz.github.io/SketchyBar/config/events |
| Tricks (color picker, popups, querying) | https://felixkratz.github.io/SketchyBar/config/tricks |
| AeroSpace integration recipe | https://nikitabobko.github.io/AeroSpace/goodies#show-aerospace-workspaces-in-sketchybar |
| Author's reference dotfiles (advanced patterns) | https://github.com/FelixKratz/dotfiles |

For features not listed: the upstream docs site is small enough to scan from the index at `https://felixkratz.github.io/SketchyBar/`.

## Layout convention in this repo

```
sketchybar/.config/sketchybar/
├── sketchybarrc        # entrypoint; bash script, must be executable
└── plugins/
    ├── aerospace.sh    # workspace highlight
    ├── battery.sh
    ├── clock.sh
    ├── front_app.sh
    └── volume.sh
```

Each plugin: shebang, reads sketchybar env (`$NAME`, `$SENDER`, `$CONFIG_DIR`, custom vars from the triggering event), writes back with `sketchybar --set $NAME prop=value`. Keep one concern per plugin.

## Item subscription cheatsheet

Built-in events (no `--add event` needed):

| Event | Fires on |
|-------|----------|
| `front_app_switched` | macOS frontmost app changed (`$INFO` = app name) |
| `volume_change` | system audio volume changed (`$INFO` = new volume) |
| `system_woke` | wake from sleep |
| `power_source_change` | AC/battery transition |
| `space_change` | macOS Mission Control space changed (not AeroSpace) |
| `display_change` | display config changed |

A subscribed item also runs its script once on initial paint (`$SENDER` empty / equals the event name depending on origin), so handle the "no env vars yet" case — typically by falling back to a CLI query (`aerospace list-workspaces --focused`, `pmset -g batt`, etc.).

## Fonts

This repo's bar uses **FiraCode Nerd Font** (already in `Brewfile` for Ghostty). The upstream example uses Hack Nerd Font. Do not switch back to Hack without adding `cask "font-hack-nerd-font"` to `Brewfile`. Sketchybar's `icon.font` / `label.font` take a Pango-style string: `"FiraCode Nerd Font:Bold:17.0"`.

If you need the proprietary app glyphs (Slack, VS Code, Discord, etc.), the community ships them as `sketchybar-app-font` — a separate font (https://github.com/kvndrsslr/sketchybar-app-font). Add the cask + use it as `icon.font` on the specific item. Don't pull this dependency in unless an item actually needs it.

## Notch and menu-bar coexistence

macOS menu bar is hidden via System Settings → Control Center → "Automatically hide and show the menu bar" → Always. With the menu bar always-hidden, sketchybar sits at the top.

- `--bar notch_width=200` carves a hole around the MacBook camera notch. Tune per display: MacBook 14"/16" ≈ 200, external displays ≈ 0.
- `--bar topmost=window` keeps the bar visible over fullscreen apps; default `topmost=off` lets fullscreen hide it.
- `--bar y_offset=N` nudges the bar vertically — use a small negative value if the bar is being clipped against the notch.

## Querying state (debug)

```bash
sketchybar --query bar                 # bar geometry + item list
sketchybar --query <item>              # full prop tree for one item
sketchybar --query default_menu_items  # macOS menubar items (for alias)
```

Log file: sketchybar writes plugin stderr to its tty when run in foreground. Under `brew services`, check `/opt/homebrew/var/log/sketchybar.log` (or wherever the plist's `StandardErrorPath` points — `brew services info sketchybar` to confirm).

## Validation commands

```bash
bash -n sketchybar/.config/sketchybar/sketchybarrc          # syntax check
bash -n sketchybar/.config/sketchybar/plugins/<name>.sh
chmod +x sketchybar/.config/sketchybar/plugins/<name>.sh    # MUST do for new plugins
sketchybar --reload                                          # apply edits to running daemon
brew services restart sketchybar                             # nuke + restart (rarely needed)
brew services info sketchybar                                # plist path, status, log paths
```

## Things easy to get wrong

- **Forgetting `chmod +x` on a new plugin.** Sketchybar will silently fail to run it; the item stays blank. `make stow` preserves the executable bit through the symlink — set it on the source file in the repo.
- **Relative `script=` paths.** `script="plugins/foo.sh"` will not resolve. Always `script="$PLUGIN_DIR/foo.sh"`.
- **`--add space` vs `--add item space.X`.** The former is a sketchybar primitive that binds to macOS Mission Control spaces and only really works with yabai. For AeroSpace, use `--add item space.<id>` + custom event. The two are not interchangeable.
- **Subscribing without defining a custom event.** `--subscribe foo my_custom_event` is a no-op if `--add event my_custom_event` was never called. There is no error — the item just never reacts.
- **Plugin reads `$1` from `click_script` instead of an arg in the `--set script=...` line.** The `script=` value is parsed as `argv` — `script="$PLUGIN_DIR/foo.sh arg1 arg2"` passes `arg1 arg2`. `click_script` is a separate string, run on click only, with no `$1`/`$2` semantics by default.
- **Reload after `chmod +x`**: changing the executable bit on the symlink target doesn't require a stow; just `sketchybar --reload` to re-run the rc.
- **`update_freq=N` plus `--subscribe`**: both work together — the item runs every N seconds AND on every subscribed event. Useful for a clock that also reacts to wake. Set `update_freq=0` (default) to disable polling and rely purely on events.
- **Bar `position=top` overlapping the menu bar**: only an issue if the menu bar isn't auto-hidden. Auto-hide is a system setting, not a sketchybar one — flag the System Settings path, don't try to "fix" it from `sketchybarrc`.
- **`brew services` keys to `sketchybar` not the formula tap name.** `brew services start sketchybar` works after `brew install FelixKratz/formulae/sketchybar` — the tap prefix is only for install, not for service management.

## Stow note

`sketchybar/` is a stow package — editing `sketchybar/.config/sketchybar/sketchybarrc` updates `~/.config/sketchybar/sketchybarrc` via symlink. No restow needed for edits to existing files. New plugins or subdirectories require `make stow PKG=sketchybar` to create the new symlink (thanks to `--no-folding` in `.stowrc`, each file is its own symlink).
