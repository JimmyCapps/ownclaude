#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run with sudo: sudo bash scripts/hosts/rollback-configure-dedicated-mac.sh"
  exit 1
fi

echo "Disabling SSH"
systemsetup -setremotelogin off
launchctl disable system/com.openssh.sshd || true

echo "Restoring standard power settings"
pmset -a sleep 10
pmset -a disksleep 10
pmset -a displaysleep 10
pmset -a standby 1
pmset -a autopoweroff 1
pmset -a hibernatemode 3
pmset -a powernap 1
pmset -a tcpkeepalive 1
pmset -a womp 0
pmset -a networkoversleep 0

echo "Disabling automatic restart after power failure"
systemsetup -setrestartpowerfailure off

echo "Current power settings"
pmset -g custom

echo "SSH status"
systemsetup -getremotelogin

echo "Baseline host rollback complete"
