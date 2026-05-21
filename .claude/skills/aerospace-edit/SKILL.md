---
name: aerospace-edit
description: Workflow for editing the aerospace package (aerospace/.config/aerospace/aerospace.toml). Enforces fetching upstream docs before writing TOML, distinguishing AeroSpace workspaces from macOS Mission Control spaces, validating via `aerospace reload-config`, and keeping the `config-version` correct. Trigger when the user asks to edit, add, remove, configure, or debug anything inside aerospace/.config/aerospace/, mentions an AeroSpace binding, workspace, gap, mode, callback, or wants to wire AeroSpace into sketchybar or another status bar.
---

# aerospace-edit

Goal: every change to `aerospace/.config/aerospace/aerospace.toml` is grounded in current upstream docs, validated by AeroSpace before reload, and aware of the AeroSpace-vs-macOS-spaces distinction that trips up most external tutorials.

## When to invoke

- Any Edit/Write touching `aerospace/.config/aerospace/aerospace.toml`
- Adding/removing a keybinding under `[mode.main.binding]` or `[mode.service.binding]`
- Changing gaps, layout defaults, normalizations, or persistent workspaces
- Adding a `window-detection-rules`/`workspace-to-monitor-force-assignment` block
- Wiring `exec-on-workspace-change`, `on-focused-monitor-changed`, `on-window-detected`, or other callbacks
- Defining a new binding mode (`[mode.<name>.binding]`)
- Debugging "binding doesn't fire" / "workspace jumps to wrong monitor" / "rule didn't apply"

## Workflow

1. **Identify what the change touches.** Top-level options (`gaps`, `key-mapping`, `default-root-container-*`) → top of file. Bindings → the right `[mode.<name>.binding]` table. Callbacks → top-level `exec-on-workspace-change` / `on-focused-monitor-changed` / `on-window-detected` arrays. Rules → `[[on-window-detected]]` / `[[workspace-to-monitor-force-assignment]]` arrays of tables.
2. **Fetch upstream docs before writing.** Use `WebFetch` against the canonical URL in the table below. AeroSpace's config schema has changed across `config-version`s — features available on v2 (current) may not have existed on v1. Memory recall is unreliable here.
3. **Respect `config-version`.** This repo pins `config-version = 2`. Some options (`persistent-workspaces`, certain rules) are v2-only. If a doc snippet says "since config-version = N", confirm N ≤ 2 before pasting.
4. **AeroSpace workspaces ≠ macOS Mission Control spaces.** AeroSpace manages its own workspace abstraction on a single macOS space per monitor; it does not call `CGSManagedDisplaySetCurrentSpace`. This matters for any integration: status bars must hook AeroSpace events (`exec-on-workspace-change`), not macOS `space_change`. Window-management commands operate on AeroSpace workspaces (`workspace 3`, `move-node-to-workspace A`), not MC spaces.
5. **Check for binding collisions.** Within a single `[mode.<name>.binding]` table, TOML rejects duplicate keys at parse time — `aerospace reload-config` will surface this. Across modes, a key may legitimately mean different things. Letter-workspace bindings (`alt-h`, `alt-j`, `alt-k`, `alt-l`) **conflict with focus directions** — the existing config drops these four letters for that reason. Preserve that.
6. **Callbacks run in `/bin/bash -c` by convention.** The form is `exec-on-workspace-change = ['/bin/bash', '-c', '...one-liner...']`. The body has access to `$AEROSPACE_FOCUSED_WORKSPACE` and `$AEROSPACE_PREV_WORKSPACE`. Keep the shell snippet short — if it grows, factor into a script under a different package and call it.
7. **Validate before reporting done.** `aerospace reload-config` parses the file and returns non-zero on any error, with a useful message pointing at the line. Always run it after edits. A silent edit that fails to reload will leave the user with the previous config until they restart AeroSpace manually.
8. **If a new external command is introduced** (a callback shells out to `jq`, `sketchybar`, `terminal-notifier`, etc.), add the binary to `Brewfile`.
9. **After editing**, mention the doc URL(s) consulted in your end-of-turn summary.

## Canonical doc URLs

| Topic | Docs |
|-------|------|
| Guide (concepts: workspaces, layouts, modes, normalizations) | https://nikitabobko.github.io/AeroSpace/guide |
| Commands reference (CLI + binding command names) | https://nikitabobko.github.io/AeroSpace/commands |
| Config reference (every key, default, since-version) | https://nikitabobko.github.io/AeroSpace/config-examples |
| Goodies (recipes: sketchybar, jankyborders, swipe gestures) | https://nikitabobko.github.io/AeroSpace/goodies |
| Window-detection rules (`on-window-detected`) | https://nikitabobko.github.io/AeroSpace/guide#on-window-detected-callback |
| Binding modes | https://nikitabobko.github.io/AeroSpace/guide#binding-modes |
| GitHub repo (releases, issues, migration notes) | https://github.com/nikitabobko/AeroSpace |

For features not listed: the guide is single-page and short — scan it from the TOC before falling back to GitHub issues.

## Workspace model in this repo

- `persistent-workspaces`: 36 entries — `1`-`9` plus `A`-`Z` minus `H`, `I`, `J`, `K`, `L` (those collide with the focus-direction letters `h`/`j`/`k`/`l`, and `I` is dropped as it's visually `1`). They persist when empty so the bar/CLI sees a stable list.
- Numeric `1`-`9` bound to `alt-1`..`alt-9` (focus) and `alt-shift-1`..`alt-shift-9` (move window).
- Letter workspaces bound to `alt-<letter>` / `alt-shift-<letter>` for the letters in `persistent-workspaces`.
- Daily-use workspaces in the sketchybar bar are numeric `1`-`9`. Letters are still hotkey-accessible but absent from the bar by design.

If you add a new persistent workspace, decide whether it also belongs in the sketchybar loop (`sketchybar-edit` skill applies).

## Callback patterns

### Notify sketchybar on workspace change

Already wired:

```toml
exec-on-workspace-change = ['/bin/bash', '-c',
    'sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE'
]
```

Triggers a `sketchybar` custom event (defined in `sketchybarrc` via `--add event aerospace_workspace_change`). See `sketchybar-edit` for the receiving side.

### Mouse follows focus across monitors

```toml
on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
```

`monitor-lazy-center` only moves if the mouse isn't already on the target monitor. Already wired.

### Assign an app to a workspace on launch

```toml
[[on-window-detected]]
if.app-id = 'com.apple.Safari'
run = ['move-node-to-workspace 2']
```

`if.app-id` matches CFBundleIdentifier. Other `if.*` selectors: `app-name-regex-substring`, `window-title-regex-substring`. `run` is an array of AeroSpace commands.

## Binding mode patterns

Modes are declared as `[mode.<name>.binding]` tables. Switch into a mode with `mode <name>` as a binding action; switch back with `mode main`. The existing `service` mode is the canonical example — entered with `alt-shift-semicolon`, exits via `esc`.

Use modes for low-frequency operations (resize, layout switch, reset) so the main mode keymap stays uncluttered. Avoid modes for things bound to alt+letter — they belong in `main`.

## CLI reference (common during debug)

```bash
aerospace --version                              # confirm binary version
aerospace reload-config                          # parse + apply current toml, errors to stderr
aerospace list-workspaces --all                  # every declared workspace
aerospace list-workspaces --focused              # currently focused workspace id
aerospace list-workspaces --monitor focused --empty no   # occupied + focused-monitor only
aerospace list-windows --workspace focused       # windows in current workspace
aerospace workspace <id>                         # switch to workspace
aerospace flatten-workspace-tree                 # reset layout (also bound in service mode)
aerospace debug-windows                          # dump full window state (issues report aid)
```

For "binding didn't fire": confirm the user is in `mode main` (the bar/menubar doesn't indicate the current mode by default — `on-mode-changed` can fix that). For "rule didn't apply": rerun `aerospace reload-config` and recheck `on-window-detected` order — rules evaluate top-to-bottom and the first match wins.

## Validation commands

```bash
aerospace reload-config                          # primary validator; errors print line + col
aerospace --version                              # confirm version supports the feature you added
```

There is no separate `aerospace --check` flag — reload is the validator.

## Things easy to get wrong

- **Pasting yabai-isms.** Many sketchybar/macOS-window-manager guides assume yabai's MC-space model. Translate before applying: `yabai -m space --focus N` → `aerospace workspace N`; `space_change` event → `aerospace_workspace_change` custom event; `--add space` → `--add item space.<id>`.
- **`alt-h`/`alt-j`/`alt-k`/`alt-l` as workspace bindings.** They're focus-direction binds in this config. Don't shadow them with `workspace H`/etc. without also dropping the focus binding — letters `H`/`I`/`J`/`K`/`L` are intentionally missing from `persistent-workspaces` for this reason.
- **`exec-on-workspace-change` as a string, not an array.** Must be `['program', 'arg1', 'arg2', ...]`. A single string silently is the wrong type and reload-config will reject it.
- **Forgetting `mode main` at the end of a service-mode action.** `[mode.service.binding]` entries that should drop back to main must `['action', 'mode main']` explicitly — otherwise the user is stuck in service mode after the action.
- **Env-var expansion inside the bash one-liner.** The TOML string is passed to `/bin/bash -c`, so `$AEROSPACE_FOCUSED_WORKSPACE` expands at exec time — correct. Do **not** wrap the bash body in TOML double-quotes if it contains `$` (the `$` is fine in TOML single-quoted strings — use those, as the existing config does).
- **`start-at-login = true` + manually launched AeroSpace.app**: harmless but creates two processes briefly. The login agent wins.
- **`workspace-to-monitor-force-assignment` and detached monitors.** If a workspace is assigned to a monitor that's currently disconnected, the workspace becomes effectively unreachable until the monitor returns. Document the assumption when adding one.
- **Editing `~/.aerospace.toml` instead of the stowed path.** The top of the file comment says "Place a copy of this config to ~/.aerospace.toml" — that's from the upstream template. In this repo it's stowed to `~/.config/aerospace/aerospace.toml`. Both paths are searched by AeroSpace, but only one is in the git tree.
- **`enable-normalization-*` toggles changing layouts unexpectedly.** Flipping these off lets degenerate containers (single-child wrappers) stick around, which surprises users. Keep them on unless there's a concrete reason.

## Stow note

`aerospace/` is a stow package — editing `aerospace/.config/aerospace/aerospace.toml` updates `~/.config/aerospace/aerospace.toml` via symlink. AeroSpace re-reads the file on `aerospace reload-config` or app restart; no stow re-run needed for edits to the existing file. If you add a new tracked file at the package root, `make stow PKG=aerospace` to create the symlink.
