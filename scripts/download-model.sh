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

huggingface-cli download \
  "$REPO_ID" \
  "$MODEL_FILENAME" \
  --local-dir "$TARGET_DIR"

echo "$TARGET_DIR/$MODEL_FILENAME"
