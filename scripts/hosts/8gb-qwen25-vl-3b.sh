#!/usr/bin/env bash

set -euo pipefail

RAW_BASE="${RAW_BASE:-${OWNCLAUDE_RAW_BASE:-https://raw.githubusercontent.com/JimmyCapps/ownclaude/main}}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ownclaude.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

MODEL_REPO="${MODEL_REPO:-ggml-org/Qwen2.5-VL-3B-Instruct-GGUF}"
MODEL_FILENAME="${MODEL_FILENAME:-Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf}"
MMPROJ_REPO="${MMPROJ_REPO:-ggml-org/Qwen2.5-VL-3B-Instruct-GGUF}"
MMPROJ_FILENAME="${MMPROJ_FILENAME:-mmproj-Qwen2.5-VL-3B-Instruct-f16.gguf}"
MODEL_ALIAS="${MODEL_ALIAS:-qwen25-vl-3b}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/qwen25-vl-3b}"
PORT="${PORT:-8001}"
CTX_SIZE="${CTX_SIZE:-8192}"

curl -fsSL "$RAW_BASE/scripts/install-llama-cpp.sh" -o "$TMP_DIR/install-llama-cpp.sh"
curl -fsSL "$RAW_BASE/scripts/download-model.sh" -o "$TMP_DIR/download-model.sh"
curl -fsSL "$RAW_BASE/scripts/start-llama-worker.sh" -o "$TMP_DIR/start-llama-worker.sh"

chmod +x "$TMP_DIR/install-llama-cpp.sh" "$TMP_DIR/download-model.sh" "$TMP_DIR/start-llama-worker.sh"

bash "$TMP_DIR/install-llama-cpp.sh"
bash "$TMP_DIR/download-model.sh" "$MODEL_REPO" "$MODEL_FILENAME" "$MODEL_DIR"
bash "$TMP_DIR/download-model.sh" "$MMPROJ_REPO" "$MMPROJ_FILENAME" "$MODEL_DIR"

exec MMPROJ_PATH="$MODEL_DIR/$MMPROJ_FILENAME" bash "$TMP_DIR/start-llama-worker.sh" \
  "$MODEL_DIR/$MODEL_FILENAME" \
  "$MODEL_ALIAS" \
  "$PORT" \
  "$CTX_SIZE"
