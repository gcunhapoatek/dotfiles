fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)

# Oh-My-Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="fox-mini"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

source <(fzf --zsh)

# Load Angular CLI autocompletion if 'ng' is available.
if command -v ng &> /dev/null; then
  source <(ng completion script)
fi

# Tool-specific environment variables
export FZF_DEFAULT_OPTS=" \
--color=bg+:-1,bg:-1,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --style=full
  --preview 'bat --style=numbers --color=always --line-range=:500 {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export NVM_DIR="$HOME/.nvm"
export SDKMAN_DIR="$HOME/.sdkman"

# Clear stale lazy-load wrappers leaked from a parent shell (e.g. Claude Code
# sandbox re-exports user-facing functions via typeset -fx but not the
# underscored helpers). Without this, the wrappers call a missing
# _nvm_lazy_load and recurse until FUNCNEST blows up.
if ! typeset -f _nvm_lazy_load >/dev/null 2>&1; then
  unset -f nvm node npm npx 2>/dev/null
fi

# NVM lazy-load: defer sourcing nvm.sh (~200-500ms) until first use of
# nvm/node/npm/npx, or when entering a directory tree containing .nvmrc.
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

_nvm_has_nvmrc_in_tree() {
  local dir=$PWD
  while [[ -n $dir ]]; do
    [[ -f $dir/.nvmrc ]] && return 0
    dir=${dir%/*}
  done
  return 1
}

_nvm_lazy_load() {
  unset -f nvm node npm npx _nvm_lazy_load _nvm_chpwd_check _nvm_has_nvmrc_in_tree
  add-zsh-hook -d chpwd _nvm_chpwd_check
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
}

_nvm_chpwd_check() {
  _nvm_has_nvmrc_in_tree && _nvm_lazy_load
}

nvm()  { _nvm_lazy_load; nvm  "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm()  { _nvm_lazy_load; npm  "$@"; }
npx()  { _nvm_lazy_load; npx  "$@"; }

add-zsh-hook chpwd _nvm_chpwd_check
_nvm_chpwd_check

eval "$(zoxide init zsh)"

[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Fastfetch only on top-level shells (skip nested tmux/zellij panes and subshells)
if [[ -z "$TMUX" && -z "$ZELLIJ" && $SHLVL -eq 1 ]] && command -v fastfetch &> /dev/null; then
  fastfetch
fi

# Per-machine overrides: secrets, work-specific paths, host quirks.
# Not tracked in the dotfiles repo.
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi
