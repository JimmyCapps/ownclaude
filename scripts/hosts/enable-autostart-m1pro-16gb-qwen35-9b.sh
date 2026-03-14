#!/usr/bin/env bash

set -euo pipefail

RAW_BASE="${RAW_BASE:-${OWNCLAUDE_RAW_BASE:-https://raw.githubusercontent.com/JimmyCapps/ownclaude/main}}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ownclaude.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

MODEL_FILENAME="${MODEL_FILENAME:-Qwen_Qwen3.5-9B-Q4_K_M.gguf}"
MODEL_ALIAS="${MODEL_ALIAS:-qwen35-9b}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/qwen35-9b}"
PORT="${PORT:-8001}"
CTX_SIZE="${CTX_SIZE:-16384}"
LABEL="${LABEL:-com.ownclaude.llama-server}"
LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-$HOME/llama.cpp/llama-server}"
WORKER_API_KEY_FILE="${WORKER_API_KEY_FILE:-$HOME/.ownclaude/llama-api-key}"

curl -fsSL "$RAW_BASE/scripts/install-llama-launchdaemon.sh" -o "$TMP_DIR/install-llama-launchdaemon.sh"
chmod +x "$TMP_DIR/install-llama-launchdaemon.sh"

if [[ ! -f "$WORKER_API_KEY_FILE" ]]; then
  echo "worker API key file not found: $WORKER_API_KEY_FILE"
  echo "run the model install script first"
  exit 1
fi

WORKER_API_KEY="$(cat "$WORKER_API_KEY_FILE")"

sudo LLAMA_SERVER_BIN="$LLAMA_SERVER_BIN" LABEL="$LABEL" API_KEY="$WORKER_API_KEY" \
  bash "$TMP_DIR/install-llama-launchdaemon.sh" \
  "$MODEL_DIR/$MODEL_FILENAME" \
  "$MODEL_ALIAS" \
  "$PORT" \
  "$CTX_SIZE"
