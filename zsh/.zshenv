# Sourced for every shell (interactive, non-interactive, scripts).
# Env vars here are visible to cron jobs, `ssh host cmd`, and script subshells.

typeset -U path PATH

# Clear stale nvm lazy-load wrappers leaked from a parent shell. Claude Code
# re-exports the user-facing nvm/node/npm/npx functions (typeset -fx) but not
# the underscored helpers defined in .zshrc. Without this guard, a leaked
# node/npm wrapper calls a missing _nvm_lazy_load and recurses until FUNCNEST
# blows up. .zshrc redefines the wrappers afterward for interactive shells.
# Lives in .zshenv (not .zprofile) so it also covers non-login shells such as
# the Claude Code sandbox, which skip .zprofile.
if ! typeset -f _nvm_lazy_load >/dev/null 2>&1; then
  unset -f nvm node npm npx 2>/dev/null
fi

# Expose the nvm "default" node version to subprocesses (the Claude Code
# sandbox, nvim → vtsls, mason-installed prettierd/eslint_d, etc.). The
# lazy-load in .zshrc only wraps `node` as a shell function — that wrapper
# never reaches child processes, and non-login shells never source it. This
# adds the real binary to PATH without sourcing nvm. Must live in .zshenv:
# non-login / non-interactive shells skip .zprofile, so a PATH entry there
# never reaches them. Set the default with `nvm alias default <ver>`.
if [[ -f "$HOME/.nvm/alias/default" ]]; then
  _nvm_default="$(<"$HOME/.nvm/alias/default")"
  # Resolve indirection (e.g. "lts/*" → concrete version).
  if [[ -f "$HOME/.nvm/alias/$_nvm_default" ]]; then
    _nvm_default="$(<"$HOME/.nvm/alias/$_nvm_default")"
  fi
  # nvm stores alias as "22.22.2" but directories are "v22.22.2".
  [[ "$_nvm_default" != v* ]] && _nvm_default="v$_nvm_default"
  if [[ -d "$HOME/.nvm/versions/node/$_nvm_default/bin" ]]; then
    path=("$HOME/.nvm/versions/node/$_nvm_default/bin" $path)
  fi
  unset _nvm_default
fi

export EDITOR="nvim"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export MANPAGER="bat -plman"

if [ -t 0 ]; then
  export GPG_TTY=$(tty)
fi
