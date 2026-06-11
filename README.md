# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a **stow package** mirroring a path relative to
`$HOME` (except `scripts/`, repo helpers, not stowed). Stowing symlinks a
package's contents into `$HOME` — e.g. `stow aerospace` links
`~/.config/aerospace/aerospace.toml` back into the repo.

## Setup

```bash
git clone <this-repo> ~/Developer/dotfiles
cd ~/Developer/dotfiles
make install   # brew bundle + symlink every package into $HOME
```

Then drop personal identity and secrets into the gitignored `*.local` files
(see below). `./install.sh` does the same as `make install` if you lack `make`.

## Commands

`make help` lists everything. Common targets:

| Target | What it does |
| --- | --- |
| `make install` | Bootstrap: `brew bundle` + restow everything |
| `make restow` | Re-symlink every package (idempotent) |
| `make stow PKG=nvim` / `make unstow PKG=nvim` | One package |
| `make check` | Dry-run stow + `brew bundle check` |
| `make clean` | Unstow every package |

## Per-machine overrides (`*.local`)

Identity and secrets stay out of the repo. Tracked configs source these
gitignored files when present:

| Override | Used by | For |
| --- | --- | --- |
| `~/.gitconfig.local` | `git/.gitconfig` | `[user]`, `commit.gpgSign`, work `includeIf` |
| `~/.zshrc.local` | `zsh/.zshrc` | private aliases, API keys, per-machine PATH |
| `~/.zprofile.local` | `zsh/.zprofile` | login-shell secrets |

## Notes

- `--no-folding` (in `.stowrc`) gives each file its own symlink, safe for
  tools that write runtime files into `~/.config/<tool>/`.
- Not brew-managed, install separately: oh-my-zsh (+ `zsh-autosuggestions`,
  `zsh-syntax-highlighting`), nvm, sdkman.
- `gh/hosts.yml` is excluded (auth tokens) — only `config.yml` is stowed.
- `yazi/` is temporarily dropped while its config is reworked.
