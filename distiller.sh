#!/usr/bin/env bash

# Absolute paths so .desktop environment doesn't break things
NODE="/usr/bin/node"  # run `which node` and update this if needed
SCRIPT="/home/kckarnige/bin/distiller.js"

LOG="$HOME/.local/share/distiller-wrapper.log"
mkdir -p "$(dirname "$LOG")"

ts() { date +"%Y-%m-%d %H:%M:%S"; }

echo "[$(ts)] Wrapper started with arg: ''" >> "$LOG"

if [ -z "$1" ]; then
  echo "[$(ts)] No URL provided; exiting." >> "$LOG"
  exit 0
fi

URL="$1"

# Start Node server in the background
"$NODE" "$SCRIPT" >> "$LOG" 2>&1 &

# Give it a moment to bind to the port
sleep 0.2

# Hit the local join endpoint
curl -s "http://127.0.0.1:27870/join?url=${URL}" >/dev/null 2>&1 &
echo "[$(ts)] Sent request to distiller server." >> "$LOG"

exit 0
