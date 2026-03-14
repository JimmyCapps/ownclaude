#!/usr/bin/env bash

set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/JimmyCapps/ownclaude/main}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ownclaude.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

MODEL_REPO="${MODEL_REPO:-bartowski/Qwen_Qwen3.5-9B-GGUF}"
MODEL_FILENAME="${MODEL_FILENAME:-Qwen_Qwen3.5-9B-Q4_K_M.gguf}"
MODEL_ALIAS="${MODEL_ALIAS:-qwen35-9b}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/qwen35-9b}"
PORT="${PORT:-8001}"
CTX_SIZE="${CTX_SIZE:-16384}"

curl -fsSL "$RAW_BASE/scripts/install-llama-cpp.sh" -o "$TMP_DIR/install-llama-cpp.sh"
curl -fsSL "$RAW_BASE/scripts/download-model.sh" -o "$TMP_DIR/download-model.sh"
curl -fsSL "$RAW_BASE/scripts/start-llama-worker.sh" -o "$TMP_DIR/start-llama-worker.sh"

chmod +x "$TMP_DIR/install-llama-cpp.sh" "$TMP_DIR/download-model.sh" "$TMP_DIR/start-llama-worker.sh"

bash "$TMP_DIR/install-llama-cpp.sh"
bash "$TMP_DIR/download-model.sh" "$MODEL_REPO" "$MODEL_FILENAME" "$MODEL_DIR"

exec bash "$TMP_DIR/start-llama-worker.sh" \
  "$MODEL_DIR/$MODEL_FILENAME" \
  "$MODEL_ALIAS" \
  "$PORT" \
  "$CTX_SIZE"
