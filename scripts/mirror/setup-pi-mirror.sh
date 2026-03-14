#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "run with sudo"
  exit 1
fi

RUN_USER="${SUDO_USER:-${USER}}"
RUN_GROUP="$(id -gn "$RUN_USER")"
REPO_URL="${REPO_URL:-https://github.com/JimmyCapps/ownclaude.git}"
BRANCH="${BRANCH:-main}"
MIRROR_ROOT="${MIRROR_ROOT:-/srv/ownclaude-mirror}"
CHECKOUT_DIR="$MIRROR_ROOT/repo"
BIN_DIR="$MIRROR_ROOT/bin"
LOG_DIR="$MIRROR_ROOT/log"
SYNC_SCRIPT="$BIN_DIR/sync.sh"
HTTP_BIND="${HTTP_BIND:-10.10.10.10}"
HTTP_PORT="${HTTP_PORT:-8091}"
SYNC_INTERVAL_MINUTES="${SYNC_INTERVAL_MINUTES:-1}"

apt-get update
apt-get install -y git python3

mkdir -p "$CHECKOUT_DIR" "$BIN_DIR" "$LOG_DIR"
chown -R "$RUN_USER:$RUN_GROUP" "$MIRROR_ROOT"

if [[ ! -d "$CHECKOUT_DIR/.git" ]]; then
  sudo -u "$RUN_USER" git clone --branch "$BRANCH" "$REPO_URL" "$CHECKOUT_DIR"
else
  sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" fetch origin "$BRANCH"
  sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" reset --hard "origin/$BRANCH"
fi

cat > "$SYNC_SCRIPT" <<EOF
#!/usr/bin/env bash
set -euo pipefail
sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" fetch origin "$BRANCH"
sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" reset --hard "origin/$BRANCH"
EOF

chmod 755 "$SYNC_SCRIPT"

cat > /etc/systemd/system/ownclaude-mirror-sync.service <<EOF
[Unit]
Description=Sync ownclaude mirror from GitHub
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$SYNC_SCRIPT
EOF

cat > /etc/systemd/system/ownclaude-mirror-sync.timer <<EOF
[Unit]
Description=Poll GitHub for ownclaude mirror updates

[Timer]
OnBootSec=30s
OnUnitActiveSec=${SYNC_INTERVAL_MINUTES}min
Unit=ownclaude-mirror-sync.service

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/ownclaude-mirror-http.service <<EOF
[Unit]
Description=Serve ownclaude mirror over HTTP
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$CHECKOUT_DIR
ExecStart=/usr/bin/python3 -m http.server $HTTP_PORT --bind $HTTP_BIND --directory $CHECKOUT_DIR
Restart=always
RestartSec=5
StandardOutput=append:$LOG_DIR/http.out.log
StandardError=append:$LOG_DIR/http.err.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now ownclaude-mirror-sync.timer
systemctl start ownclaude-mirror-sync.service
systemctl enable --now ownclaude-mirror-http.service

echo "Mirror ready at http://$HTTP_BIND:$HTTP_PORT/"
echo "Repo root: $CHECKOUT_DIR"
