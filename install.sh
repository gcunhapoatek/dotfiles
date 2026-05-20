#!/usr/bin/env bash
# Bootstrap script: installs stow if needed, then symlinks all packages into $HOME.
# Idempotent — safe to re-run.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

if ! command -v stow >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing GNU stow via Homebrew..."
    brew install stow
  else
    echo "Error: GNU stow is not installed and Homebrew is unavailable." >&2
    echo "Install stow manually, then re-run this script." >&2
    exit 1
  fi
fi

# Every top-level dir is a stow package, except for repo metadata.
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
  echo "No packages found in $DOTFILES_DIR" >&2
  exit 1
fi

echo "Stowing packages into $HOME:"
printf '  - %s\n' "${PACKAGES[@]}"

# --restow handles re-runs cleanly (unstow then stow), so config additions just work.
stow --restow "${PACKAGES[@]}"

echo
echo "Done. Symlinks created in ~/.config/ pointing at $DOTFILES_DIR"
