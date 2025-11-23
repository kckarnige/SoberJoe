#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Distiller"
APP_ID="distiller"
SOBER_FLATPAK_ID="org.vinegarhq.Sober"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_BIN="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/${APP_ID}.desktop"

echo "Installing $APP_NAME for user: $USER"

# -------------------------------
# 1) Check for Sober (Flatpak)
# -------------------------------
if command -v flatpak >/dev/null 2>&1; then
  if flatpak info "$SOBER_FLATPAK_ID" >/dev/null 2>&1; then
    echo "Sober is installed (Flatpak: $SOBER_FLATPAK_ID)"
  else
    echo "Sober not found! Make sure to install it via Flatpak!"
  fi
else
  echo "Flatpak not found! Make sure it and Sober are installed first!"
fi

# -------------------------------
# 2) Check for Node.js
# -------------------------------
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js not found! Please install it with your distro's package manager!"
  exit 1
else
  NODE_BIN="$(command -v node)"
  echo "Node.js is installed at: $NODE_BIN"
fi

# -------------------------------
# 3) Install scripts
# -------------------------------
mkdir -p "$INSTALL_BIN"

echo "Installing scripts into: $INSTALL_BIN"

# Copy JS server
cp "$SCRIPT_DIR/distiller.js" "$INSTALL_BIN/distiller.js"

# Copy wrapper and make it executable
cp "$SCRIPT_DIR/distiller.sh" "$INSTALL_BIN/distiller.sh"
chmod +x "$INSTALL_BIN/distiller.sh"

# Patch wrapper to use detected node and correct JS path
# This assumes the top of distiller.sh has lines starting with NODE= and SCRIPT=
if grep -q '^NODE=' "$INSTALL_BIN/distiller.sh"; then
  sed -i "s|^NODE=.*$|NODE=\"$NODE_BIN\"|" "$INSTALL_BIN/distiller.sh"
fi

if grep -q '^SCRIPT=' "$INSTALL_BIN/distiller.sh"; then
  sed -i "s|^SCRIPT=.*$|SCRIPT=\"$INSTALL_BIN/distiller.js\"|" "$INSTALL_BIN/distiller.sh"
fi

echo "Scripts installed:"
echo "    $INSTALL_BIN/distiller.sh"
echo "    $INSTALL_BIN/distiller.js"

# -------------------------------
# 4) Install .desktop file
# -------------------------------
mkdir -p "$DESKTOP_DIR"

echo "Writing desktop entry to: $DESKTOP_FILE"

cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Distiller
Comment=Intercepts Roblox launches Sober with proper forwarding, useful for Firefox users!
Exec=$INSTALL_BIN/distiller.sh %u
Terminal=false
MimeType=x-scheme-handler/roblox;x-scheme-handler/roblox-player;
Categories=Game;
NoDisplay=true
Icon=org.vinegarhq.Sober
EOF

# -------------------------------
# 5) Register as handler for roblox:// and roblox-player://
# -------------------------------
if command -v xdg-mime >/dev/null 2>&1; then
  echo "Registering URL handlers with xdg-mime"
  xdg-mime default "${APP_ID}.desktop" x-scheme-handler/roblox || true
  xdg-mime default "${APP_ID}.desktop" x-scheme-handler/roblox-player || true
else
  echo "xdg-mime not found! Could not register URL handlers!"
fi

# Try to update desktop database (optional)
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" || true
fi

clear
echo
echo "Done!"
echo
echo "Installed scripts at:  $INSTALL_BIN"
echo "Desktop file is at:  $DESKTOP_FILE"
echo
echo "If roblox:// links aren't opening in Distiller yet, try logging out and back in,"
echo "or set the handler manually in your desktop's 'Default Applications' / 'URL Handlers' settings."
echo