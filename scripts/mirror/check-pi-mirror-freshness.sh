#!/usr/bin/env bash

set -euo pipefail

MIRROR_BASE="${1:-http://10.10.10.10:8091}"

curl -fsSL "$MIRROR_BASE/status.json"
