#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run with sudo"
  exit 1
fi

LABEL="${1:-com.ownclaude.llama-server}"
WORK_DIR="${WORK_DIR:-/opt/ownclaude}"
PLIST_PATH="/Library/LaunchDaemons/${LABEL}.plist"
STAGED_BIN="$WORK_DIR/bin/llama-server"
LOG_DIR="$WORK_DIR/log"

launchctl bootout system "$PLIST_PATH" >/dev/null 2>&1 || true
rm -f "$PLIST_PATH"
rm -f "$STAGED_BIN"

echo "Removed LaunchDaemon: $PLIST_PATH"
echo "Removed staged binary: $STAGED_BIN"
echo "Logs retained in: $LOG_DIR"
