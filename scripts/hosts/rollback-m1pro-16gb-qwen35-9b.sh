#!/usr/bin/env bash

set -euo pipefail

MODEL_ALIAS="${MODEL_ALIAS:-qwen35-9b}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/qwen35-9b}"
LLAMA_CPP_DIR="${LLAMA_CPP_DIR:-$HOME/llama.cpp}"

pkill -f "llama-server.*${MODEL_ALIAS}" || true
pkill -f "${MODEL_DIR}" || true

rm -rf "$MODEL_DIR"
rm -rf "$LLAMA_CPP_DIR"

echo "Removed model dir: $MODEL_DIR"
echo "Removed llama.cpp dir: $LLAMA_CPP_DIR"
