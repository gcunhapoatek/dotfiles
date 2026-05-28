
eval "$(/opt/homebrew/bin/brew shellenv)"

path=("$HOME/.local/bin" $path)

# Clear stale nvm lazy-load wrappers leaked from a parent shell (e.g. Claude
# Code sandbox re-exports user-facing functions via typeset -fx but not the
# underscored helpers defined in .zshrc). Login non-interactive shells skip
# .zshrc, so the guard lives here. Without it, leaked node/npm/npx wrappers
# call a missing _nvm_lazy_load and recurse until FUNCNEST blows up.
if ! typeset -f _nvm_lazy_load >/dev/null 2>&1; then
  unset -f nvm node npm npx 2>/dev/null
fi

# Expose the nvm "default" node version to non-interactive subprocesses
# (nvim → vtsls, mason-installed prettierd/eslint_d, etc.). The lazy-load
# in .zshrc only wraps `node` as a shell function — that wrapper never
# reaches child processes. This adds the real binary to PATH at login,
# without sourcing nvm. Set the default with `nvm alias default <ver>`.
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

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Per-machine overrides: secrets, work-specific paths, host quirks.
# Not tracked in the dotfiles repo.
if [[ -f ~/.zprofile.local ]]; then
  source ~/.zprofile.local
fi
