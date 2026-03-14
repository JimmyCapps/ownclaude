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
RUNNER_PATH="$BIN_DIR/${LABEL}.sh"

mkdir -p "$BIN_DIR" "$LOG_DIR"

cat > "$RUNNER_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ARGS=(
  --model "$MODEL_PATH"
  --alias "$MODEL_ALIAS"
  --host 0.0.0.0
  --port "$PORT"
  --ctx-size "$CTX_SIZE"
  --threads -1
  --flash-attn on
  --kv-unified
  --cache-type-k q8_0
  --cache-type-v q8_0
  --batch-size 1024
  --ubatch-size 512
  --no-webui
)
if [[ -n "$MMPROJ_PATH" ]]; then
  ARGS+=(--mmproj "$MMPROJ_PATH")
fi
exec "$LLAMA_SERVER_BIN" "\${ARGS[@]}"
EOF

chmod 755 "$RUNNER_PATH"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${RUNNER_PATH}</string>
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

chmod 644 "$PLIST_PATH"
chown root:wheel "$PLIST_PATH"

launchctl bootout system "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl bootstrap system "$PLIST_PATH"
launchctl enable "system/${LABEL}"
launchctl kickstart -k "system/${LABEL}"

echo "Installed LaunchDaemon: $PLIST_PATH"
echo "Runner script: $RUNNER_PATH"
echo "Logs:"
echo "  $LOG_DIR/${LABEL}.out.log"
echo "  $LOG_DIR/${LABEL}.err.log"
