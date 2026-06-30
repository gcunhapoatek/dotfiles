# Brewfile for the dotfiles in this repo.
# Install everything: brew bundle --file=Brewfile
# Show what's missing:  brew bundle check --file=Brewfile

# ----- Taps -----
tap "nikitabobko/tap"               # provides the aerospace cask
tap "FelixKratz/formulae"           # provides sketchybar

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
brew "tree-sitter-cli"              # CLI used by nvim-treesitter main branch to build parsers
brew "ripgrep"                      # required by snacks.picker grep + vim grepprg

# ----- Lint / validation (local mirror of .github/workflows/lint.yml) -----
brew "shellcheck"                   # shell script linter, per CLAUDE.md validation matrix
brew "stylua"                       # lua formatter for nvim/ — `stylua --check`

# ----- Git stack -----
brew "gh"                           # github cli, → gh/ package
brew "git-delta"                    # diff pager (referenced by [core] pager = delta)

# ----- GPG signing (used by ~/.gitconfig.local: commit.gpgSign = true) -----
brew "gnupg"
brew "pinentry-mac"                 # macOS-native passphrase prompt for gpg-agent

# ----- GUI apps -----
cask "aerospace"                    # tiling window manager → aerospace/ package
cask "ghostty"                      # terminal emulator → ghostty/ package
brew "sketchybar"                   # macOS status bar → sketchybar/ package
brew "borders"                      # JankyBorders — focused-window borders, launched by aerospace after-startup-command
brew "nowplaying-cli"               # used by sketchybar media plugin (media_change event deprecated on macOS 26)
brew "coreutils"                    # gtimeout — caps the XPC-backed nowplaying-cli call in sketchybar media plugin

# ----- Fonts (referenced by ghostty/.config/ghostty/config) -----
cask "font-fira-code-nerd-font"
cask "font-sketchybar-app-font"     # ligature glyphs for sketchybar front_app icon
