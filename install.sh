#!/usr/bin/env bash
# Bootstrap: install Brewfile deps and symlink every package into $HOME.
# Idempotent — safe to re-run. Requires macOS + Homebrew.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# 1. Brewfile dependencies (includes stow itself).
echo "==> Installing Brewfile dependencies"
brew bundle --file=Brewfile

# 2. Discover stow packages: every top-level directory except repo metadata.
EXCLUDE=(.git .github .claude scripts)
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

# 3. Stow each package independently so one conflict doesn't abort the rest.
#    --target/--dir explicit so the script works for any user.
echo "==> Stowing into $HOME:"
fail=0
for pkg in "${PACKAGES[@]}"; do
  if err="$(stow --target="$HOME" --dir="$DOTFILES_DIR" --restow "$pkg" 2>&1)"; then
    echo "  ✓ $pkg"
  else
    echo "  ✗ $pkg" >&2
    printf '%s\n' "$err" | sed 's/^/      /' >&2
    fail=1
  fi
done

echo
if [[ $fail -eq 0 ]]; then
  echo "Done. Symlinks in \$HOME now point at $DOTFILES_DIR"
else
  echo "Some packages failed to stow — see above." >&2
  exit 1
fi
