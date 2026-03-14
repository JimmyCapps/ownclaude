#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

MODEL_REPO="${MODEL_REPO:-bartowski/Qwen3.5-4B-GGUF}"
MODEL_FILENAME="${MODEL_FILENAME:-Qwen3.5-4B-Q4_K_M.gguf}"
MODEL_ALIAS="${MODEL_ALIAS:-qwen35-4b}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/qwen35-4b}"
PORT="${PORT:-8001}"
CTX_SIZE="${CTX_SIZE:-8192}"

bash "$ROOT_DIR/scripts/install-llama-cpp.sh"
bash "$ROOT_DIR/scripts/download-model.sh" "$MODEL_REPO" "$MODEL_FILENAME" "$MODEL_DIR"

exec bash "$ROOT_DIR/scripts/start-llama-worker.sh" \
  "$MODEL_DIR/$MODEL_FILENAME" \
  "$MODEL_ALIAS" \
  "$PORT" \
  "$CTX_SIZE"
