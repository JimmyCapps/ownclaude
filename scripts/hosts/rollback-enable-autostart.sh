#!/usr/bin/env bash

set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/JimmyCapps/ownclaude/main}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ownclaude.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

LABEL="${LABEL:-com.ownclaude.llama-server}"

curl -fsSL "$RAW_BASE/scripts/remove-llama-launchdaemon.sh" -o "$TMP_DIR/remove-llama-launchdaemon.sh"
chmod +x "$TMP_DIR/remove-llama-launchdaemon.sh"

sudo bash "$TMP_DIR/remove-llama-launchdaemon.sh" "$LABEL"
