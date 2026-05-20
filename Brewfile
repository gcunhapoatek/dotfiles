# Brewfile for the dotfiles in this repo.
# Install everything: brew bundle --file=Brewfile
# Show what's missing:  brew bundle check --file=Brewfile

# ----- Taps -----
tap "nikitabobko/tap"               # provides the aerospace cask

# ----- Core dotfile management -----
brew "stow"                         # symlink farm — drives this repo

# ----- Shell experience (sourced/init'd by zsh/.zshrc) -----
brew "fzf"                          # fuzzy finder, sourced by .zshrc
brew "zoxide"                       # smarter cd, init'd by .zshrc
brew "fastfetch"                    # boot banner in .zshrc
brew "bat"                          # used as MANPAGER in .zshrc

# ----- Terminal tools mapped 1:1 to dotfile packages -----
brew "btop"                         # → btop/ package
brew "eza"                          # → eza/ package
brew "lazygit"                      # → lazygit/ package
brew "neovim"                       # → nvim/ package, also $EDITOR
brew "spotify_player"               # → spotify-player/ package

# ----- Git stack -----
brew "gh"                           # github cli, → gh/ package
brew "git-delta"                    # diff pager (referenced by [core] pager = delta)

# ----- GPG signing (used by ~/.gitconfig.local: commit.gpgSign = true) -----
brew "gnupg"
brew "pinentry-mac"                 # macOS-native passphrase prompt for gpg-agent

# ----- Misc dev tooling -----
brew "taplo"                        # TOML linter/formatter

# ----- GUI apps -----
cask "aerospace"                    # tiling window manager → aerospace/ package
cask "ghostty"                      # terminal emulator → ghostty/ package
cask "cursor"                       # IDE → cursor/ package

# ----- Fonts (referenced by ghostty/.config/ghostty/config) -----
cask "font-fira-code-nerd-font"
