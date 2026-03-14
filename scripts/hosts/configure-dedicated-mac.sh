#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run with sudo: sudo bash scripts/hosts/configure-dedicated-mac.sh"
  exit 1
fi

echo "Enabling SSH"
systemsetup -setremotelogin on
launchctl enable system/com.openssh.sshd
launchctl kickstart -k system/com.openssh.sshd

echo "Configuring power management for always-on operation"
pmset -a sleep 0
pmset -a disksleep 0
pmset -a displaysleep 30
pmset -a standby 0
pmset -a autopoweroff 0
pmset -a hibernatemode 0
pmset -a powernap 0
pmset -a tcpkeepalive 1
pmset -a womp 1
pmset -a networkoversleep 0

echo "Restarting automatically after power failure"
systemsetup -setrestartpowerfailure on

echo "Current power settings"
pmset -g custom

echo "SSH status"
systemsetup -getremotelogin

echo "Baseline host configuration complete"
