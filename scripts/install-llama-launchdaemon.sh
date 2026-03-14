#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run with sudo"
  exit 1
fi

if [[ $# -lt 2 ]]; then
  echo "usage: sudo $0 MODEL_PATH MODEL_ALIAS [PORT] [CTX_SIZE]"
  exit 1
fi

MODEL_PATH="$1"
MODEL_ALIAS="$2"
PORT="${3:-8001}"
CTX_SIZE="${4:-16384}"
MMPROJ_PATH="${MMPROJ_PATH:-}"

LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-$HOME/llama.cpp/llama-server}"
LABEL="${LABEL:-com.ownclaude.llama-server}"
WORK_DIR="${WORK_DIR:-/opt/ownclaude}"
BIN_DIR="$WORK_DIR/bin"
LOG_DIR="$WORK_DIR/log"
PLIST_PATH="/Library/LaunchDaemons/${LABEL}.plist"
STAGED_BIN="$BIN_DIR/llama-server"

if [[ ! -x "$LLAMA_SERVER_BIN" ]]; then
  echo "llama-server not found at $LLAMA_SERVER_BIN"
  exit 1
fi

mkdir -p "$WORK_DIR" "$BIN_DIR" "$LOG_DIR"
chown -R root:wheel "$WORK_DIR"
chmod 755 "$WORK_DIR" "$BIN_DIR" "$LOG_DIR"

cp "$LLAMA_SERVER_BIN" "$STAGED_BIN"
chown root:wheel "$STAGED_BIN"
chmod 755 "$STAGED_BIN"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${STAGED_BIN}</string>
    <string>--model</string>
    <string>${MODEL_PATH}</string>
    <string>--alias</string>
    <string>${MODEL_ALIAS}</string>
    <string>--host</string>
    <string>0.0.0.0</string>
    <string>--port</string>
    <string>${PORT}</string>
    <string>--ctx-size</string>
    <string>${CTX_SIZE}</string>
    <string>--threads</string>
    <string>-1</string>
    <string>--flash-attn</string>
    <string>on</string>
    <string>--kv-unified</string>
    <string>--cache-type-k</string>
    <string>q8_0</string>
    <string>--cache-type-v</string>
    <string>q8_0</string>
    <string>--batch-size</string>
    <string>1024</string>
    <string>--ubatch-size</string>
    <string>512</string>
    <string>--no-webui</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>${WORK_DIR}</string>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/${LABEL}.out.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/${LABEL}.err.log</string>
  <key>ProcessType</key>
  <string>Background</string>
</dict>
</plist>
EOF

if [[ -n "$MMPROJ_PATH" ]]; then
  /usr/libexec/PlistBuddy -c "Add :ProgramArguments:25 string --mmproj" "$PLIST_PATH"
  /usr/libexec/PlistBuddy -c "Add :ProgramArguments:26 string $MMPROJ_PATH" "$PLIST_PATH"
fi

chmod 644 "$PLIST_PATH"
chown root:wheel "$PLIST_PATH"

launchctl bootout system "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl enable "system/${LABEL}"
launchctl bootstrap system "$PLIST_PATH"
launchctl kickstart -k "system/${LABEL}"

echo "Installed LaunchDaemon: $PLIST_PATH"
echo "Logs:"
echo "  $LOG_DIR/${LABEL}.out.log"
echo "  $LOG_DIR/${LABEL}.err.log"
