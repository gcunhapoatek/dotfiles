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

# Helper names use hyphens, not a leading underscore: Claude Code's shell
# snapshot (~/.claude/shell-snapshots/) strips every function whose name starts
# with `_`. The node/npm/npx/nvm wrappers below ARE captured; an underscored
# helper would not be, leaving the wrappers calling a missing function and
# recursing until FUNCNEST aborts. Hyphenated names survive the snapshot.
nvm-has-nvmrc-in-tree() {
  local dir=$PWD
  while [[ -n $dir ]]; do
    [[ -f $dir/.nvmrc ]] && return 0
    dir=${dir%/*}
  done
  return 1
}

nvm-lazy-load() {
  unset -f nvm node npm npx nvm-lazy-load nvm-chpwd-check nvm-has-nvmrc-in-tree
  add-zsh-hook -d chpwd nvm-chpwd-check
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
}

nvm-chpwd-check() {
  nvm-has-nvmrc-in-tree && nvm-lazy-load
}

# Interactive shells lazy-load nvm on first use. Non-interactive shells (Claude
# Code's Bash tool, scripts) skip the wrapper and exec the real node/npm/npx
# that .zshenv put on PATH — sourcing nvm.sh costs ~300ms and would be re-paid
# on every command since each runs in a fresh shell. nvm itself isn't a PATH
# binary, so its wrapper always loads.
nvm()  { nvm-lazy-load; nvm  "$@"; }
node() { if [[ -o interactive ]]; then nvm-lazy-load; node "$@"; else command node "$@"; fi; }
npm()  { if [[ -o interactive ]]; then nvm-lazy-load; npm  "$@"; else command npm  "$@"; fi; }
npx()  { if [[ -o interactive ]]; then nvm-lazy-load; npx  "$@"; else command npx  "$@"; fi; }

add-zsh-hook chpwd nvm-chpwd-check
nvm-chpwd-check

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
