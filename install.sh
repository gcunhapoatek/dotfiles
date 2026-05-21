#!/usr/bin/env bash
# Bootstrap: install Brewfile deps and symlink every package into $HOME.
# Idempotent — safe to re-run. Requires macOS + Homebrew.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# 1. Brewfile dependencies (includes stow itself).
echo "==> Installing Brewfile dependencies"
brew bundle --file=Brewfile

# 3. Discover stow packages: every top-level directory except repo metadata.
EXCLUDE=(.git .github)
PACKAGES=()
for dir in */; do
  pkg="${dir%/}"
  skip=false
  for ex in "${EXCLUDE[@]}"; do
    [[ "$pkg" == "$ex" ]] && skip=true && break
  done
  $skip || PACKAGES+=("$pkg")
done

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  echo "Error: no stow packages found in $DOTFILES_DIR" >&2
  exit 1
fi

# 4. Stow them. --target/--dir explicit so the script works for any user.
echo "==> Stowing into $HOME:"
printf '  - %s\n' "${PACKAGES[@]}"
stow --target="$HOME" --dir="$DOTFILES_DIR" --restow "${PACKAGES[@]}"

echo
echo "Done. Symlinks in \$HOME now point at $DOTFILES_DIR"
