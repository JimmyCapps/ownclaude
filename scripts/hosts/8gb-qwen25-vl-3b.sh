#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

MODEL_REPO="${MODEL_REPO:-bartowski/Qwen2.5-VL-3B-Instruct-GGUF}"
MODEL_FILENAME="${MODEL_FILENAME:-Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf}"
MODEL_ALIAS="${MODEL_ALIAS:-qwen25-vl-3b}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/qwen25-vl-3b}"
PORT="${PORT:-8001}"
CTX_SIZE="${CTX_SIZE:-8192}"

bash "$ROOT_DIR/scripts/install-llama-cpp.sh"
bash "$ROOT_DIR/scripts/download-model.sh" "$MODEL_REPO" "$MODEL_FILENAME" "$MODEL_DIR"

exec bash "$ROOT_DIR/scripts/start-llama-worker.sh" \
  "$MODEL_DIR/$MODEL_FILENAME" \
  "$MODEL_ALIAS" \
  "$PORT" \
  "$CTX_SIZE"
