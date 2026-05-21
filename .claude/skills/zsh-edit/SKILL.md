---
name: zsh-edit
description: Workflow for editing the zsh package (zsh/.zshrc, zsh/.zprofile) and its plugin/tool integrations. Enforces fetching upstream docs before writing init lines, validating syntax with `zsh -n`, and keeping secrets out of tracked files. Trigger when the user asks to edit, add, remove, audit, validate, or debug anything in zsh/.zshrc, zsh/.zprofile, ~/.zshrc.local, ~/.zprofile.local, or mentions a shell tool wired into those files (oh-my-zsh, fzf, nvm, zoxide, sdkman, brew shellenv, etc.).
---

# zsh-edit

Goal: every change to the `zsh/` package is grounded in current upstream docs, syntax-checked before the user reloads, and free of secrets that would leak through git.

## When to invoke

- Any Edit/Write touching `zsh/.zshrc`, `zsh/.zprofile`
- Adding/removing an oh-my-zsh plugin, a tool init (`eval "$(foo init zsh)"`), or a completion source line
- Adding env vars, aliases, functions, PATH entries
- Debugging slow shell startup, broken prompt, missing command, or duplicate PATH entries
- Auditing what loads at login vs interactive shell

## Workflow

1. **Identify which file owns the change.** Login-only env (PATH bootstraps, `brew shellenv`, secrets needed by GUI apps) → `.zprofile`. Interactive features (aliases, prompts, completions, key bindings, plugins) → `.zshrc`. If unsure, see the "Startup file order" section.
2. **Fetch upstream docs before writing init lines.** Use `WebFetch` against the canonical URL in the table below. `eval "$(tool init zsh)"` patterns drift (flag names, hook names, what they emit). Do not paste from memory.
3. **Check for duplication.** Grep `zsh/.zshrc` and `zsh/.zprofile` for the same `export`, `eval`, `source`, or `alias` before adding. Duplicate `export PATH="...:$PATH"` lines compound on every reload.
4. **Order matters — preserve it.** Several lines have ordering constraints (see "Ordering rules" below). When inserting, place relative to existing anchors, not at the bottom by default.
5. **Validate syntax.** Run `zsh -n /Users/gabrieldacunha/Developer/dotfiles/zsh/.zshrc` (and `.zprofile` if touched) before reporting done. Parse errors here are silent at next login — the user only notices when something breaks.
6. **If a new external tool is introduced**, add its formula/cask to `Brewfile` in the same change. The repo's contract is that `make install` brings up a fresh machine; an init line referencing an uninstalled binary breaks that.
7. **Reload guidance.** Tell the user how to apply: `exec zsh` for a full re-init (recommended when `.zprofile` changed or PATH was touched), or `source ~/.zshrc` for interactive-only tweaks.
8. **After editing**, mention the doc URL(s) consulted in your end-of-turn summary.

## Secrets policy — never commit

The tracked files **must not contain**: API keys, tokens, work-specific hostnames, employer-identifying paths, private aliases. These live in `~/.zshrc.local` / `~/.zprofile.local`, which the tracked files already source at the end. If the user asks you to "add my OPENAI_API_KEY", write it to `~/.zshrc.local` (create if missing) — never to `zsh/.zshrc`. The `.local` files are gitignored and outside the stow tree.

If you find an apparent secret already in a tracked file, flag it and offer to migrate it to `~/.zshrc.local` rather than silently leaving it.

## Startup file order

zsh sources files in this order. Knowing this prevents "why isn't this variable set in tmux?" debugging.

| File | When | Used here for |
|------|------|---------------|
| `.zshenv` | every shell (interactive, non-interactive, scripts) | not used in this repo |
| `.zprofile` | login shells only | `brew shellenv` (bootstraps PATH, MANPATH, INFOPATH), OrbStack init, `.zprofile.local` |
| `.zshrc` | interactive shells | everything else: oh-my-zsh, plugins, completions, prompts, aliases, tool inits |
| `.zlogin` | login shells, after `.zshrc` | not used in this repo |

**Implication**: anything sourced only in `.zshrc` will not be present in a non-interactive subshell (e.g. `ssh host 'mycmd'` or a cron job). If a tool needs to work everywhere, its env must live in `.zprofile` (or `.zshenv`, but this repo doesn't use one).

## Ordering rules (don't reorder casually)

In `.zshrc`:

1. `fpath=(...)` extensions **before** `source $ZSH/oh-my-zsh.sh` — oh-my-zsh runs `compinit`, which freezes `fpath`.
2. `plugins=(...)` array set **before** `source $ZSH/oh-my-zsh.sh` — the source line consumes it.
3. `source $ZSH/oh-my-zsh.sh` **before** any `eval "$(tool init zsh)"` that registers widgets or completions — oh-my-zsh's compinit must run first so completions are available to register against.
4. `zsh-syntax-highlighting` must be sourced **last** among zsh-users plugins (it hooks ZLE and other plugins' hooks must already be installed). Oh-my-zsh's `plugins=()` array ordering handles this — keep `zsh-syntax-highlighting` last in that list.
5. `~/.zshrc.local` source line stays at the **very bottom** so per-machine overrides win over everything tracked.

In `.zprofile`:

1. `eval "$(/opt/homebrew/bin/brew shellenv)"` first — everything below depends on `brew --prefix` being in PATH.
2. `~/.zprofile.local` source line at the bottom.

## Canonical doc URLs

| Tool | Docs |
|------|------|
| zsh (builtins, options, parameter expansion) | https://zsh.sourceforge.io/Doc/Release/zsh_toc.html |
| oh-my-zsh | https://github.com/ohmyzsh/ohmyzsh/wiki — plugin list: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins — theme list: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes |
| zsh-autosuggestions | https://github.com/zsh-users/zsh-autosuggestions |
| zsh-syntax-highlighting | https://github.com/zsh-users/zsh-syntax-highlighting |
| fzf | https://github.com/junegunn/fzf — shell integration: https://github.com/junegunn/fzf#setting-up-shell-integration — options: `man fzf` |
| nvm | https://github.com/nvm-sh/nvm — auto-switch recipe (in-repo): https://github.com/nvm-sh/nvm#calling-nvm-use-automatically-in-a-directory-with-a-nvmrc-file |
| zoxide | https://github.com/ajeetdsouza/zoxide |
| sdkman | https://sdkman.io/install — https://sdkman.io/usage |
| bat (used as MANPAGER) | https://github.com/sharkdp/bat |
| fastfetch | https://github.com/fastfetch-cli/fastfetch |
| Homebrew shellenv | https://docs.brew.sh/Manpage#shellenv-bashzshfishpowershell |
| OrbStack shell integration | https://docs.orbstack.dev/ |
| GNU Stow | https://www.gnu.org/software/stow/manual/stow.html |

For tools not listed: find the upstream repo, fetch its README, then look for a section titled "Installation", "Shell integration", or "zsh setup". If those are missing, fetch the `man` page text via `man <tool> | col -bx`.

## Adding an oh-my-zsh plugin

1. Check the plugin exists: it must be either a [built-in plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins) (no install needed) or a custom plugin cloned to `$ZSH_CUSTOM/plugins/<name>` (default `~/.oh-my-zsh/custom/plugins/`). Custom plugins are **not tracked** by this repo — they install separately.
2. Add the name to the `plugins=(...)` array in `.zshrc`. Keep `zsh-syntax-highlighting` **last**.
3. If the plugin requires a tool (e.g. `kubectl` for the `kubectl` plugin), add the tool to `Brewfile`.
4. Fetch the plugin's README from the oh-my-zsh plugins directory link above before adding — many plugins add aliases or env vars the user may already have differently.

## Adding a new tool init

Pattern: `eval "$(tool init zsh)"`. Before writing it:

1. Fetch the tool's docs to confirm the exact init invocation (some use `tool init zsh`, others `tool shell-init zsh`, others print to stdout that needs `--cmd` or `--hook`).
2. Place it **after** `source $ZSH/oh-my-zsh.sh` in `.zshrc` (so its widgets register against the live ZLE).
3. Add the binary to `Brewfile`.
4. If the init takes >50ms, consider lazy-loading (e.g. function stub that replaces itself on first call). Don't pre-optimize — measure with `time zsh -ic exit` first.

## Validation commands

```bash
zsh -n /Users/gabrieldacunha/Developer/dotfiles/zsh/.zshrc      # syntax check, no exec
zsh -n /Users/gabrieldacunha/Developer/dotfiles/zsh/.zprofile
time zsh -ic exit                                                # startup time (interactive)
zsh -xv -ic exit 2>&1 | head -100                                # trace what runs at startup
```

For "command not found after edit" reports: `echo $PATH | tr ':' '\n'` to see resolved order, then `which -a <cmd>` to find duplicates/shadows.

## Things easy to get wrong

- **Editing the symlinked file vs source**: `~/.zshrc` is a symlink into this repo via stow. Edit `zsh/.zshrc` here, not the symlinked target — both work (they're the same inode) but only one is in the repo's working tree for `git diff`.
- **`export FOO="..."` with embedded `$VAR`**: if `$VAR` isn't set yet, expansion silently produces empty. Order your exports so dependencies come first (e.g. `XDG_*` before any var that references `$XDG_CONFIG_HOME`).
- **Quoting in `MANPAGER`**: the existing MANPAGER line uses heavily nested quoting (`'\''` to escape single quotes inside `sh -c '...'`). If you touch it, test with `MANPAGER=... man ls` before committing.
- **`source <(fzf --zsh)`**: process substitution. `fzf` must be on PATH at the moment `.zshrc` runs. Since `brew shellenv` runs in `.zprofile`, this works for login shells; non-login interactive shells (rare on macOS Terminal but common in some terminals) may not have brew's PATH yet — guard with `command -v fzf &>/dev/null && source <(fzf --zsh)` if it becomes a problem.
- **`load-nvmrc` runs on every `chpwd`**: it shells out to `nvm` (slow). If the user reports laggy `cd`, this is likely it. Don't remove without asking — the user wired it deliberately.
- **`fastfetch` at the bottom of `.zshrc`**: runs on every interactive shell open. Acceptable for top-level terminals; annoying for nested shells. The existing `command -v` guard only protects against missing binary, not nesting.
- **PATH duplication on reload**: `export PATH="$HOME/.local/bin:$PATH"` is idempotent in spelling but not in effect — re-sourcing `.zshrc` prepends again. Harmless but cosmetically noisy. To dedupe: `typeset -U path` (declare `path` array unique) near the top of `.zshrc`.
- **Oh-my-zsh updates clobber custom changes** only if you edit files under `~/.oh-my-zsh/` directly. Everything in this repo lives outside that tree — safe.

## Stow note

`zsh/` is a stow package — `zsh/.zshrc` symlinks to `~/.zshrc`, `zsh/.zprofile` to `~/.zprofile`. Edits to existing files take effect on next shell (no restow). If you add a new tracked file at the package root (e.g. `zsh/.zshenv`), run `make stow PKG=zsh` to create the symlink.

The per-machine override files (`~/.zshrc.local`, `~/.zprofile.local`) live directly in `$HOME` and are **not** stow-managed — they exist outside this repo and are gitignored by convention.
