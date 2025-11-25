#!/usr/bin/env bash
set -euo pipefail

# Check if being ran with Sudo
if [ "$(id -u)" -eq 0 ]; then
    echo "Joe must NOT be installed as root or via sudo."
    exit 1
fi

APP_NAME="Joe"
APP_ID="soberjoe"
SOBER_ID="org.vinegarhq.Sober"

INSTALL_BIN="$HOME/.local/bin/soberjoe"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/${APP_ID}.desktop"

echo "Uninstalling $APP_NAME for user: $USER"

rm -rf "$INSTALL_BIN"
rm "$DESKTOP_FILE"

if [ -f "$HOME/.local/share/applications/$SOBER_ID.desktop" ]; then
  echo "Registering Sober as a Roblox handler..."
  sed -i "/^#MimeType=.*x-scheme-handler\/roblox/s/^#//" "$HOME/.local/share/applications/$SOBER_ID.desktop"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  rm ~/.local/share/applications/mimeinfo.cache || true
  update-desktop-database ~/.local/share/applications || true
fi

echo
echo "Done!"
echo