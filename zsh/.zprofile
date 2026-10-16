eval "$(/opt/homebrew/bin/brew shellenv)"

path=("$HOME/.local/bin" $path)

# Re-prepend nvm's default node (defined in .zshenv): /etc/zprofile's
# path_helper and brew shellenv above pushed it behind system/Homebrew dirs,
# where a brew-installed node would shadow it.
nvm-prepend-default-bin

# Per-machine overrides: secrets, work-specific paths, host quirks.
# Not tracked in the dotfiles repo.
if [[ -f ~/.zprofile.local ]]; then
  source ~/.zprofile.local
fi
