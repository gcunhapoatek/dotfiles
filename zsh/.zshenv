# Sourced for every shell (interactive, non-interactive, scripts).
# Env vars here are visible to cron jobs, `ssh host cmd`, and script subshells.

typeset -U path PATH

# Defense-in-depth: clear nvm lazy-load wrappers leaked from a parent shell
# without their helper. The wrappers and helpers are normally carried together
# via Claude Code's shell snapshot (helpers are hyphen-named so the snapshot
# keeps them). If a wrapper ever arrives without nvm-lazy-load, drop it so the
# real node/npm/npx on PATH (added below) resolve instead of recursing until
# FUNCNEST aborts. .zshrc redefines the wrappers afterward for interactive
# shells. Lives in .zshenv (not .zprofile) so it also covers non-login shells
# such as the Claude Code sandbox, which skip .zprofile.
if ! typeset -f nvm-lazy-load >/dev/null 2>&1; then
  unset -f nvm node npm npx 2>/dev/null
fi

# Expose the nvm "default" node version to subprocesses (the Claude Code
# sandbox, nvim → vtsls, mason-installed prettierd/eslint_d, etc.). The
# lazy-load in .zshrc only wraps `node` as a shell function — that wrapper
# never reaches child processes, and non-login shells never source it. This
# adds the real binary to PATH without sourcing nvm. Must live in .zshenv:
# non-login / non-interactive shells skip .zprofile, so a PATH entry there
# never reaches them. Set the default with `nvm alias default <ver>`.
# .zprofile calls this again: macOS path_helper (/etc/zprofile) and brew
# shellenv push their entries ahead of it in login shells.
nvm-prepend-default-bin() {
  [[ -f "$HOME/.nvm/alias/default" ]] || return 0
  local version
  version="$(<"$HOME/.nvm/alias/default")"
  # Resolve indirection (e.g. "lts/*" → concrete version).
  if [[ -f "$HOME/.nvm/alias/$version" ]]; then
    version="$(<"$HOME/.nvm/alias/$version")"
  fi
  # nvm stores alias as "22.22.2" but directories are "v22.22.2".
  [[ "$version" != v* ]] && version="v$version"
  if [[ -d "$HOME/.nvm/versions/node/$version/bin" ]]; then
    path=("$HOME/.nvm/versions/node/$version/bin" $path)
  fi
}
nvm-prepend-default-bin

export EDITOR="nvim"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
