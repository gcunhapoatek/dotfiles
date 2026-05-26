#!/usr/bin/env bash
# Refresh sketchybar app-font icon map from the latest upstream release.
# Source: https://github.com/kvndrsslr/sketchybar-app-font
#
# Writes to: sketchybar/.config/sketchybar/icon_map.sh
# Warns if the installed font cask version differs from the fetched map version
# (mismatched releases can render boxes for ligatures present in one but not the other).

set -euo pipefail

REPO="kvndrsslr/sketchybar-app-font"
LATEST_URL="https://github.com/$REPO/releases/latest/download/icon_map.sh"
FONT_CASK="font-sketchybar-app-font"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$DOTFILES_DIR/sketchybar/.config/sketchybar/icon_map.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "==> fetching latest icon_map.sh from $REPO"
curl -fsSL -o "$TMP" "$LATEST_URL"

# Resolve the release tag for logging + font-version mismatch check. Non-fatal.
LATEST_TAG=""
if command -v gh >/dev/null 2>&1; then
  LATEST_TAG="$(gh release view --repo "$REPO" --json tagName --jq .tagName 2>/dev/null || true)"
fi
echo "    upstream release: ${LATEST_TAG:-unknown}"

if ! bash -n "$TMP"; then
  echo "ERROR: downloaded file failed bash -n syntax check" >&2
  exit 1
fi

if ! grep -q '^function __icon_map' "$TMP"; then
  echo "ERROR: downloaded file missing __icon_map function" >&2
  exit 1
fi

INSTALLED_FONT="$(brew list --cask --versions "$FONT_CASK" 2>/dev/null | awk '{print $2}' || true)"
if [ -n "$INSTALLED_FONT" ] && [ -n "$LATEST_TAG" ] && [ "v$INSTALLED_FONT" != "$LATEST_TAG" ]; then
  echo "WARNING: installed $FONT_CASK is v$INSTALLED_FONT, map is $LATEST_TAG."
  echo "         Run: brew upgrade --cask $FONT_CASK   (to keep font and map in sync)"
fi

mv "$TMP" "$TARGET"
trap - EXIT
echo "    wrote $TARGET ($(wc -l <"$TARGET" | tr -d ' ') lines)"
echo "    reload sketchybar with: sketchybar --reload"
