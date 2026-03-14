#!/usr/bin/env bash

set -euo pipefail

WORKER_API_KEY_FILE="${WORKER_API_KEY_FILE:-$HOME/.ownclaude/llama-api-key}"

mkdir -p "$(dirname "$WORKER_API_KEY_FILE")"
chmod 700 "$(dirname "$WORKER_API_KEY_FILE")"

if [[ ! -f "$WORKER_API_KEY_FILE" ]]; then
  python3 - <<'PY' > "$WORKER_API_KEY_FILE"
import secrets
print(f"sk-llama-{secrets.token_urlsafe(32)}")
PY
  chmod 600 "$WORKER_API_KEY_FILE"
fi

cat "$WORKER_API_KEY_FILE"
