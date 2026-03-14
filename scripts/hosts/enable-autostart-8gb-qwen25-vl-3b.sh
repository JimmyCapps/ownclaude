#!/usr/bin/env bash

set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/JimmyCapps/ownclaude/main}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ownclaude.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

MODEL_FILENAME="${MODEL_FILENAME:-Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf}"
MMPROJ_FILENAME="${MMPROJ_FILENAME:-mmproj-Qwen2.5-VL-3B-Instruct-f16.gguf}"
MODEL_ALIAS="${MODEL_ALIAS:-qwen25-vl-3b}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/qwen25-vl-3b}"
PORT="${PORT:-8001}"
CTX_SIZE="${CTX_SIZE:-8192}"
LABEL="${LABEL:-com.ownclaude.llama-server}"
LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-$HOME/llama.cpp/llama-server}"

curl -fsSL "$RAW_BASE/scripts/install-llama-launchdaemon.sh" -o "$TMP_DIR/install-llama-launchdaemon.sh"
chmod +x "$TMP_DIR/install-llama-launchdaemon.sh"

sudo LLAMA_SERVER_BIN="$LLAMA_SERVER_BIN" LABEL="$LABEL" MMPROJ_PATH="$MODEL_DIR/$MMPROJ_FILENAME" \
  bash "$TMP_DIR/install-llama-launchdaemon.sh" \
  "$MODEL_DIR/$MODEL_FILENAME" \
  "$MODEL_ALIAS" \
  "$PORT" \
  "$CTX_SIZE"
