#!/usr/bin/env bash

set -euo pipefail

BREW_BIN="${BREW_BIN:-}"
LLAMA_CPP_DIR="${LLAMA_CPP_DIR:-$HOME/llama.cpp}"

if [[ -z "$BREW_BIN" ]]; then
  if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
  else
    echo "Homebrew is required. Install it first: https://brew.sh"
    exit 1
  fi
fi

"$BREW_BIN" install cmake git wget huggingface-cli

if [[ ! -d "$LLAMA_CPP_DIR/.git" ]]; then
  git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA_CPP_DIR"
fi

git -C "$LLAMA_CPP_DIR" pull --ff-only
cmake -S "$LLAMA_CPP_DIR" -B "$LLAMA_CPP_DIR/build" -DBUILD_SHARED_LIBS=OFF
cmake --build "$LLAMA_CPP_DIR/build" -j

if [[ -x "$LLAMA_CPP_DIR/build/bin/llama-server" ]]; then
  ln -sf "$LLAMA_CPP_DIR/build/bin/llama-server" "$LLAMA_CPP_DIR/llama-server"
fi

echo "llama.cpp installed at $LLAMA_CPP_DIR"
