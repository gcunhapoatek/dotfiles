# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

Each top-level directory is a **stow package** that mirrors the structure
relative to `$HOME`. Stowing a package symlinks its contents into the
matching path under `$HOME`.

```
dotfiles/
├── .stowrc                 # default stow options (target=$HOME, --no-folding)
├── Brewfile                # tool dependencies for `brew bundle`
├── install.sh              # bootstrap: installs stow + stows everything
├── aerospace/.config/aerospace/aerospace.toml
├── bat/.config/bat/{config,themes/}
├── btop/.config/btop/{btop.conf,themes/}
├── cursor/.config/cursor/cli-config.json
├── eza/.config/eza/theme.yml
├── fastfetch/.config/fastfetch/{config.jsonc,logo.txt}
├── gh/.config/gh/config.yml          # hosts.yml is intentionally NOT tracked
├── ghostty/.config/ghostty/{config,themes/}
├── lazygit/.config/lazygit/config.yml
├── nvim/.config/nvim/{init.lua,lua/,lazy-lock.json}
├── spotify-player/.config/spotify-player/{app.toml,theme.toml}
├── git/.gitconfig                    # top-level dotfile
└── zsh/{.zshrc,.zprofile}            # top-level dotfiles
```

`stow aerospace` creates the symlink

```
~/.config/aerospace/aerospace.toml -> ~/Developer/dotfiles/aerospace/.config/aerospace/aerospace.toml
```

## Setup on a new machine

```bash
git clone <this-repo> ~/Developer/dotfiles
cd ~/Developer/dotfiles

# 1. Install tool dependencies (Homebrew + Brewfile)
brew bundle --file=Brewfile

# 2. Stow every package into $HOME
./install.sh

# 3. Drop your personal info into the gitignored *.local files
#    (see "Per-machine overrides" below)
```

`install.sh` will install GNU stow via Homebrew if needed and then symlink
every package. The `Brewfile` handles everything else (fzf, zoxide, neovim,
ghostty, fonts, etc.) — see the file itself for the annotated list.

## Day-to-day usage

| Action | Command |
| --- | --- |
| Stow everything | `./install.sh` (uses `stow --restow`, idempotent) |
| Stow one package | `stow nvim` |
| Unstow (remove symlinks) one package | `stow -D nvim` |
| Re-stow after adding files | `stow -R nvim` |
| Dry run (preview) | `stow -n -v nvim` |

`.stowrc` configures `--target=$HOME --dir=~/Developer/dotfiles --no-folding`,
so you can run `stow <pkg>` from anywhere inside the repo.

## Adding a new tool

1. Create the package mirror: `mkdir -p newtool/.config/newtool`.
2. Move the live config in: `mv ~/.config/newtool/* newtool/.config/newtool/`.
3. Stow it: `stow newtool`.
4. Commit.

## Adding non-`.config` dotfiles

Stow packages can mirror any path relative to `$HOME`, not just `.config/`.
The `zsh/` package is the example — it puts files at the package root so
they land directly in `$HOME`:

```
zsh/
├── .zshrc        # → ~/.zshrc
└── .zprofile     # → ~/.zprofile
```

Then `stow zsh`. Same pattern works for `.gitconfig`, `.tmux.conf`, etc.

## Per-machine overrides (`*.local` files)

Personal identity, secrets, and host-specific tweaks don't belong in a
shared dotfiles repo. The configs here source local override files if
they exist, all of which are gitignored:

| Config | Override file | Loaded via |
| --- | --- | --- |
| `git/.gitconfig` | `~/.gitconfig.local` | `[include] path = ~/.gitconfig.local` |
| `zsh/.zshrc` | `~/.zshrc.local` | `if [[ -f ~/.zshrc.local ]]; then source ~/.zshrc.local; fi` |
| `zsh/.zprofile` | `~/.zprofile.local` | same pattern |

Use these for things like:

- `~/.gitconfig.local` — `[user]` block (name, email, signingkey),
  `commit.gpgSign`, work-specific `includeIf` paths
- `~/.zshrc.local` — private aliases, API keys exported as env vars,
  per-machine PATH entries
- `~/.zprofile.local` — login-shell-only secrets or host setup

If the override file doesn't exist, the parent config is a no-op for
that section. New forkers get a working baseline and add their own
identity/secrets without ever touching the tracked files.

## Tool dependencies (`Brewfile`)

Every brew formula and cask the configs in this repo depend on is declared
in `Brewfile` at the repo root. To install or refresh them:

```bash
brew bundle --file=Brewfile        # install everything that's missing
brew bundle check --file=Brewfile  # show what's not installed yet
brew bundle cleanup --file=Brewfile --force  # uninstall things not in Brewfile
```

A few things aren't brew-managed and are installed separately on a fresh
machine (run these after `brew bundle`):

- **oh-my-zsh** + plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`)
  referenced by `zsh/.zshrc`
- **nvm** (Node version manager) — used by `.zshrc` for the `load-nvmrc`
  hook
- **sdkman** — used by `.zshrc` and `.zprofile` for JVM tooling

## Notes

- **`gh/hosts.yml`** is intentionally excluded — it contains auth tokens. It
  stays in `~/.config/gh/` as a real file and stow only links `config.yml`.
- **`git/.gitconfig`** is identity-free. Personal `[user]`, `commit.gpgSign`,
  and per-client `includeIf` directives live in `~/.gitconfig.local`
  (gitignored). See the "Per-machine overrides" section above.
- **`--no-folding`** is enabled so each file becomes its own symlink (rather
  than letting stow collapse a whole directory into one symlink). This makes
  it safe for tools that write extra runtime files into `~/.config/<tool>/`.
- **`yazi/`** is currently dropped from the repo (its config is being
  reworked). Add it back as a stow package when ready.
