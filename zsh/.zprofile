
eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Per-machine overrides: secrets, work-specific paths, host quirks.
# Not tracked in the dotfiles repo.
if [[ -f ~/.zprofile.local ]]; then
  source ~/.zprofile.local
fi
