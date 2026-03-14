#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 MODEL_PATH MODEL_ALIAS [PORT] [CTX_SIZE]"
  exit 1
fi

MODEL_PATH="$1"
MODEL_ALIAS="$2"
PORT="${3:-8001}"
CTX_SIZE="${4:-16384}"
MMPROJ_PATH="${MMPROJ_PATH:-}"
API_KEY="${API_KEY:-}"

LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-$HOME/llama.cpp/llama-server}"

if [[ ! -x "$LLAMA_SERVER_BIN" ]]; then
  echo "llama-server not found at $LLAMA_SERVER_BIN"
  echo "set LLAMA_SERVER_BIN or install llama.cpp first"
  exit 1
fi

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

if [[ -n "$API_KEY" ]]; then
  ARGS+=(--api-key "$API_KEY")
fi

exec "$LLAMA_SERVER_BIN" "${ARGS[@]}"
