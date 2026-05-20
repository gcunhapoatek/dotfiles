#!/usr/bin/env bash
# Bootstrap: install Brewfile deps, ensure stow is present, and symlink
# every package into $HOME. Idempotent — safe to re-run.
#
# This script is portable: no hardcoded paths, derives everything from
# the script's own location and $HOME.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# 1. Brewfile dependencies (best-effort; skip if Homebrew unavailable).
if [[ -f Brewfile ]]; then
  if command -v brew >/dev/null 2>&1; then
    echo "==> Installing Brewfile dependencies"
    brew bundle --file=Brewfile
  else
    echo "==> Skipping Brewfile (Homebrew not installed)" >&2
  fi
fi

# 2. Make sure stow itself is on PATH.
if ! command -v stow >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "==> Installing GNU stow"
    brew install stow
  else
    echo "Error: GNU stow is not installed and Homebrew is unavailable." >&2
    echo "Install stow manually, then re-run this script." >&2
    exit 1
  fi
fi

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
