#!/usr/bin/env bash

set -euo pipefail

RAW_BASE="${RAW_BASE:-${OWNCLAUDE_RAW_BASE:-https://raw.githubusercontent.com/JimmyCapps/ownclaude/main}}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ownclaude.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

MODEL_REPO="${MODEL_REPO:-bartowski/Qwen_Qwen3.5-9B-GGUF}"
MODEL_FILENAME="${MODEL_FILENAME:-Qwen_Qwen3.5-9B-Q4_K_M.gguf}"
MODEL_ALIAS="${MODEL_ALIAS:-qwen35-9b}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/qwen35-9b}"
PORT="${PORT:-8001}"
CTX_SIZE="${CTX_SIZE:-16384}"
WORKER_API_KEY_FILE="${WORKER_API_KEY_FILE:-$HOME/.ownclaude/llama-api-key}"

curl -fsSL "$RAW_BASE/scripts/install-llama-cpp.sh" -o "$TMP_DIR/install-llama-cpp.sh"
curl -fsSL "$RAW_BASE/scripts/download-model.sh" -o "$TMP_DIR/download-model.sh"
curl -fsSL "$RAW_BASE/scripts/ensure-worker-api-key.sh" -o "$TMP_DIR/ensure-worker-api-key.sh"
curl -fsSL "$RAW_BASE/scripts/hosts/prereq.sh" -o "$TMP_DIR/prereq.sh"

chmod +x "$TMP_DIR/install-llama-cpp.sh" "$TMP_DIR/download-model.sh" "$TMP_DIR/ensure-worker-api-key.sh" "$TMP_DIR/prereq.sh"

if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]] && [[ ! -x /usr/local/bin/brew ]]; then
  bash "$TMP_DIR/prereq.sh"
fi

bash "$TMP_DIR/install-llama-cpp.sh"
bash "$TMP_DIR/download-model.sh" "$MODEL_REPO" "$MODEL_FILENAME" "$MODEL_DIR"
WORKER_API_KEY="$(WORKER_API_KEY_FILE="$WORKER_API_KEY_FILE" bash "$TMP_DIR/ensure-worker-api-key.sh")"

PRIMARY_IFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
HOST_IP=""
if [[ -n "$PRIMARY_IFACE" ]]; then
  HOST_IP="$(ipconfig getifaddr "$PRIMARY_IFACE" 2>/dev/null || true)"
fi

if [[ -z "$HOST_IP" ]]; then
  HOST_IP="SET_HOST_IP"
fi

cat <<EOF
Worker install complete.
Generated worker API key file: $WORKER_API_KEY_FILE

LiteLLM request body:
{
  "model_name": "REPLACE_WITH_LITELLM_ALIAS",
  "litellm_params": {
    "model": "openai/$MODEL_ALIAS",
    "api_base": "http://$HOST_IP:$PORT/v1",
    "api_key": "$WORKER_API_KEY"
  }
}
EOF
