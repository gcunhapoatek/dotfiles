# Oh-My-Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="fox-mini"
plugins=(git)

source $ZSH/oh-my-zsh.sh

source <(fzf --zsh)

# Angular CLI completion, cached: `ng completion script` boots node (~300ms),
# so regenerate only when the ng install is newer than the cache.
if (( $+commands[ng] )); then
  ng_completion="$XDG_CACHE_HOME/zsh/ng-completion.zsh"
  if [[ ! -s $ng_completion || $commands[ng] -nt $ng_completion ]]; then
    mkdir -p "${ng_completion:h}"
    ng completion script >| "$ng_completion"
  fi
  source "$ng_completion"
  unset ng_completion
fi

# Tool-specific environment variables
export MANPAGER="bat -plman"
export GPG_TTY=$TTY

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

# Node logo via Nerd Font glyph (nf-dev-nodejs, U+E718). Falls back to a plain
# tag if the terminal font lacks it — but every terminal here uses a Nerd Font.
NVMRC_NODE_ICON=$''

# nvmrc-msg <color> <message> — print an icon-prefixed, colored status line.
# Colors are zsh %F codes: green (use/install ok), yellow (revert), red (miss).
nvmrc-msg() {
  print -P "%F{$1}${NVMRC_NODE_ICON}%f  $2"
}

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local requested
    requested="$(<"$nvmrc_path")"
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$requested")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvmrc-msg yellow "node %F{cyan}${requested}%f not installed — running %Bnvm install%b"
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvmrc-msg green "switching to node %F{cyan}${nvmrc_node_version}%f %F{8}(.nvmrc)%f"
      nvm use --silent
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    nvmrc-msg yellow "left .nvmrc tree — reverting to node %F{cyan}$(nvm version default)%f %F{8}(default)%f"
    nvm use default --silent
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

# SDKMAN lazy-load: sdkman-init.sh costs ~250ms per shell. Expose installed
# candidates the way init does (current/bin on PATH, <NAME>_HOME), and defer
# the rest until the first `sdk` call. Safe while sdkman_auto_env=false in
# $SDKMAN_DIR/etc/config — init's chpwd hook is the only thing deferred away.
for candidate_dir in "$SDKMAN_DIR"/candidates/*/current(N); do
  path=("$candidate_dir/bin" $path)
  export "${(U)${candidate_dir:h:t}}_HOME=$candidate_dir"
done
unset candidate_dir

sdk() {
  unset -f sdk
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk "$@"
}

# Fastfetch only on top-level shells (skip nested tmux/zellij panes and subshells)
if [[ -z "$TMUX" && -z "$ZELLIJ" && $SHLVL -eq 1 ]] && command -v fastfetch &> /dev/null; then
  fastfetch
fi

# Per-machine overrides: secrets, work-specific paths, host quirks.
# Not tracked in the dotfiles repo.
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
fi

# Brew-installed plugins. zsh-syntax-highlighting must be sourced last.
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
