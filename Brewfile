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
brew "zsh-autosuggestions"          # sourced by .zshrc
brew "zsh-syntax-highlighting"      # sourced last by .zshrc

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
brew "lua-language-server"          # on PATH for Claude Code's lua-lsp plugin (nvim uses mason's copy)

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
brew "media-control"                # now-playing stream for sketchybar media_stream.sh (nowplaying-cli returns null on macOS 26)
brew "jq"                           # parses media-control stream + `sketchybar --query displays` JSON in sketchybar plugins

# ----- Fonts (referenced by ghostty/.config/ghostty/config) -----
cask "font-fira-code-nerd-font"
cask "font-sketchybar-app-font"     # ligature glyphs for sketchybar front_app icon
