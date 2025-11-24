#!/usr/bin/env bash
set -euo pipefail

# Check if being ran with Sudo
if [ "$(id -u)" -eq 0 ]; then
    echo "Joe must NOT be installed as root or via sudo."
    exit 1
fi

APP_NAME="Joe"
APP_ID="soberjoe"
SOBER_FLATPAK_ID="org.vinegarhq.Sober"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_BIN="$HOME/.local/bin/soberjoe"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/${APP_ID}.desktop"

echo "Installing $APP_NAME for user: $USER"

# -------------------------------
# 1) Check for Sober (Flatpak)
# -------------------------------
if command -v flatpak >/dev/null 2>&1; then
  if flatpak info "$SOBER_FLATPAK_ID" >/dev/null 2>&1; then
    echo "Sober is installed via Flatpak"
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
# 3) Install needed files
# -------------------------------
echo "Installing files..."

mkdir -p "$INSTALL_BIN"

cp "$SCRIPT_DIR/joe.png" "$INSTALL_BIN/soberjoe-icon.png"
cp "$SCRIPT_DIR/soberjoe.js" "$INSTALL_BIN/soberjoe.js"
cp "$SCRIPT_DIR/soberjoe-wrapper.sh" "$INSTALL_BIN/soberjoe-wrapper.sh"
# Make the wrapper executable
chmod +x "$INSTALL_BIN/soberjoe-wrapper.sh"

# Patch wrapper to use detected node and correct JS path
# This assumes the top of soberjoe-wrapper.sh has lines starting with NODE= and SCRIPT=
if grep -q '^NODE=' "$INSTALL_BIN/soberjoe-wrapper.sh"; then
  sed -i "s|^NODE=.*$|NODE=\"$NODE_BIN\"|" "$INSTALL_BIN/soberjoe-wrapper.sh"
fi

if grep -q '^SCRIPT=' "$INSTALL_BIN/soberjoe-wrapper.sh"; then
  sed -i "s|^SCRIPT=.*$|SCRIPT=\"$INSTALL_BIN/soberjoe.js\"|" "$INSTALL_BIN/soberjoe-wrapper.sh"
fi

# -------------------------------
# 4) Install .desktop file
# -------------------------------
mkdir -p "$DESKTOP_DIR"

cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Joe
Comment=A Roblox URL handler that makes things work as it should, no matter what app tries to launch Sober.
Exec=$INSTALL_BIN/soberjoe-wrapper.sh %u
Terminal=false
MimeType=x-scheme-handler/roblox;x-scheme-handler/roblox-player;
Categories=Game;
NoDisplay=true
Icon=$INSTALL_BIN/soberjoe-icon.png
EOF

# -------------------------------
# 5) Register as handler for roblox:// and roblox-player://
# -------------------------------
if command -v xdg-mime >/dev/null 2>&1; then
  echo "Registering as default Roblox handler for: $USER"
  xdg-mime default "${APP_ID}.desktop" x-scheme-handler/roblox || true
  xdg-mime default "${APP_ID}.desktop" x-scheme-handler/roblox-player || true
else
  echo "xdg-mime not found! Could not register URL handlers!"
fi

# Try to update desktop database (optional)
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" || true
fi

echo
echo "Done!"
echo
echo "Installed at:  $INSTALL_BIN"
echo "Desktop file is at:  $DESKTOP_FILE"
echo
echo "If Roblox links aren't opening with Joe yet, make sure it's set as the default"
echo "handler in your desktop's 'Default Applications' settings. If it is, try logging out then back in."
echo