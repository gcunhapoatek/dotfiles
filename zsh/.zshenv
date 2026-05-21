# Sourced for every shell (interactive, non-interactive, scripts).
# Env vars here are visible to cron jobs, `ssh host cmd`, and script subshells.

typeset -U path PATH

export EDITOR="nvim"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export MANPAGER="bat -plman"

if [ -t 0 ]; then
  export GPG_TTY=$(tty)
fi
