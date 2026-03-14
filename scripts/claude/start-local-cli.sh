#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.local}"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || true)}"
DEFAULT_MODEL="${CLAUDE_MODEL:-local-dev-primary}"
LITELLM_BASE_URL="${LITELLM_BASE_URL:-http://10.10.10.10:4000}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

if [[ -z "$CLAUDE_BIN" ]]; then
  echo "Claude Code CLI not found on PATH"
  exit 1
fi

if [[ -z "${LITELLM_API_KEY:-}" && -z "${ANTHROPIC_AUTH_TOKEN:-}" && -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "Set LITELLM_API_KEY, ANTHROPIC_AUTH_TOKEN, or ANTHROPIC_API_KEY in $ENV_FILE or the environment"
  exit 1
fi

export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-$LITELLM_BASE_URL}"
export ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-${LITELLM_API_KEY:-${ANTHROPIC_API_KEY:-}}}"
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$ANTHROPIC_AUTH_TOKEN}"

exec "$CLAUDE_BIN" \
  --setting-sources project,local \
  --model "$DEFAULT_MODEL" \
  "$@"
