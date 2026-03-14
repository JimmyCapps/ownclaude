#!/usr/bin/env bash

set -euo pipefail

if command -v brew >/dev/null 2>&1; then
  echo "Homebrew already installed at $(command -v brew)"
  exit 0
fi

echo "Installing Homebrew from the internet via brew.sh"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew install completed but brew is not on PATH yet"
  echo "Open a new shell or run the shellenv command printed by the installer, then continue"
  exit 1
fi

echo "Homebrew installed at $(command -v brew)"
