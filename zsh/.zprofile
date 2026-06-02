
eval "$(/opt/homebrew/bin/brew shellenv)"

path=("$HOME/.local/bin" $path)

# nvm default-node PATH and the lazy-load recursion guard moved to .zshenv so
# they also reach non-login shells (the Claude Code sandbox skips .zprofile).

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Per-machine overrides: secrets, work-specific paths, host quirks.
# Not tracked in the dotfiles repo.
if [[ -f ~/.zprofile.local ]]; then
  source ~/.zprofile.local
fi
