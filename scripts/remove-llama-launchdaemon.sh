#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run with sudo"
  exit 1
fi

LABEL="${1:-com.ownclaude.llama-server}"
WORK_DIR="${WORK_DIR:-/opt/ownclaude}"
PLIST_PATH="/Library/LaunchDaemons/${LABEL}.plist"
RUNNER_PATH="$WORK_DIR/bin/${LABEL}.sh"
LOG_DIR="$WORK_DIR/log"

launchctl bootout system "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl disable "system/${LABEL}" >/dev/null 2>&1 || true

rm -f "$PLIST_PATH" "$RUNNER_PATH"

echo "Removed LaunchDaemon: $PLIST_PATH"
echo "Removed runner: $RUNNER_PATH"
echo "Logs retained in: $LOG_DIR"
