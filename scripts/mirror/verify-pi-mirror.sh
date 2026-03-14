#!/usr/bin/env bash

set -euo pipefail

MIRROR_BASE="${1:-http://10.10.10.10:8091}"

curl -fsSL "$MIRROR_BASE/scripts/install-llama-launchdaemon.sh" | sed -n '1,40p'
curl -fsSL "$MIRROR_BASE/scripts/hosts/enable-autostart-8gb-qwen35-4b.sh" | sed -n '1,30p'
