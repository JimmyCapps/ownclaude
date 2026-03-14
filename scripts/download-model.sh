#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 HUGGINGFACE_REPO MODEL_FILENAME [TARGET_DIR]"
  exit 1
fi

REPO_ID="$1"
MODEL_FILENAME="$2"
TARGET_DIR="${3:-$HOME/models}"

mkdir -p "$TARGET_DIR"

if command -v hf >/dev/null 2>&1; then
  hf download \
    "$REPO_ID" \
    "$MODEL_FILENAME" \
    --local-dir "$TARGET_DIR"
elif command -v huggingface-cli >/dev/null 2>&1; then
  huggingface-cli download \
    "$REPO_ID" \
    "$MODEL_FILENAME" \
    --local-dir "$TARGET_DIR"
else
  echo "Neither 'hf' nor 'huggingface-cli' is available"
  exit 1
fi

if [[ ! -f "$TARGET_DIR/$MODEL_FILENAME" ]]; then
  echo "Model file not found after download: $TARGET_DIR/$MODEL_FILENAME"
  exit 1
fi

echo "$TARGET_DIR/$MODEL_FILENAME"
