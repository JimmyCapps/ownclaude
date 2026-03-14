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
PUBLIC_DIR="$MIRROR_ROOT/public"
MODEL_SOURCE_DIR="${MODEL_SOURCE_DIR:-/srv/models}"
PUBLIC_MODELS_DIR="$PUBLIC_DIR/models"
BIN_DIR="$MIRROR_ROOT/bin"
LOG_DIR="$MIRROR_ROOT/log"
SYNC_SCRIPT="$BIN_DIR/sync.sh"
RENDER_STALE_SCRIPT="$BIN_DIR/render-stale-tree.sh"
STATUS_SCRIPT="$BIN_DIR/status.sh"
HTTP_BIND="${HTTP_BIND:-10.10.10.10}"
HTTP_PORT="${HTTP_PORT:-8091}"
SYNC_INTERVAL_MINUTES="${SYNC_INTERVAL_MINUTES:-1}"

apt-get update
apt-get install -y git python3 rsync

mkdir -p "$CHECKOUT_DIR" "$PUBLIC_DIR" "$PUBLIC_MODELS_DIR" "$BIN_DIR" "$LOG_DIR"
chown -R "$RUN_USER:$RUN_GROUP" "$MIRROR_ROOT"

if [[ ! -d "$CHECKOUT_DIR/.git" ]]; then
  sudo -u "$RUN_USER" git clone --branch "$BRANCH" "$REPO_URL" "$CHECKOUT_DIR"
else
  sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" fetch origin "$BRANCH"
  sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" reset --hard "origin/$BRANCH"
fi

cat > "$RENDER_STALE_SCRIPT" <<EOF
#!/usr/bin/env bash
set -euo pipefail

PUBLIC_DIR="${PUBLIC_DIR}"
STATUS_MESSAGE="\${1:-stale script mirror; retry shortly}"
mkdir -p "\$PUBLIC_DIR/scripts/hosts" "\$PUBLIC_DIR/scripts/mirror"
mkdir -p "\$PUBLIC_DIR/models"

write_stale() {
  local path="\$1"
  mkdir -p "\$(dirname "\$path")"
  cat > "\$path" <<'EOS'
#!/usr/bin/env bash
echo "stale script mirror; retry shortly" >&2
exit 1
EOS
  chmod 755 "\$path"
}

for path in \
  "\$PUBLIC_DIR/scripts/install-llama-cpp.sh" \
  "\$PUBLIC_DIR/scripts/download-model.sh" \
  "\$PUBLIC_DIR/scripts/install-llama-launchdaemon.sh" \
  "\$PUBLIC_DIR/scripts/remove-llama-launchdaemon.sh" \
  "\$PUBLIC_DIR/scripts/start-llama-worker.sh" \
  "\$PUBLIC_DIR/scripts/hosts/configure-dedicated-mac.sh" \
  "\$PUBLIC_DIR/scripts/hosts/8gb-qwen35-4b.sh" \
  "\$PUBLIC_DIR/scripts/hosts/8gb-qwen25-vl-3b.sh" \
  "\$PUBLIC_DIR/scripts/hosts/m1pro-16gb-qwen35-9b.sh" \
  "\$PUBLIC_DIR/scripts/hosts/enable-autostart-8gb-qwen35-4b.sh" \
  "\$PUBLIC_DIR/scripts/hosts/enable-autostart-8gb-qwen25-vl-3b.sh" \
  "\$PUBLIC_DIR/scripts/hosts/enable-autostart-m1pro-16gb-qwen35-9b.sh" \
  "\$PUBLIC_DIR/scripts/hosts/rollback-enable-autostart.sh" \
  "\$PUBLIC_DIR/scripts/hosts/rollback-configure-dedicated-mac.sh" \
  "\$PUBLIC_DIR/scripts/hosts/rollback-8gb-qwen35-4b.sh" \
  "\$PUBLIC_DIR/scripts/hosts/rollback-8gb-qwen25-vl-3b.sh" \
  "\$PUBLIC_DIR/scripts/hosts/rollback-m1pro-16gb-qwen35-9b.sh"; do
  write_stale "\$path"
done

cat > "\$PUBLIC_DIR/status.json" <<EOS
{"status":"stale","message":"\$STATUS_MESSAGE"}
EOS
EOF

chmod 755 "$RENDER_STALE_SCRIPT"

cat > "$SYNC_SCRIPT" <<EOF
#!/usr/bin/env bash
set -euo pipefail

PUBLIC_DIR="${PUBLIC_DIR}"
CHECKOUT_DIR="${CHECKOUT_DIR}"
MODEL_SOURCE_DIR="${MODEL_SOURCE_DIR}"
PUBLIC_MODELS_DIR="${PUBLIC_MODELS_DIR}"
LOG_DIR="${LOG_DIR}"
BRANCH="${BRANCH}"

"${RENDER_STALE_SCRIPT}" "mirror syncing in progress"
sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" fetch origin "$BRANCH"
REMOTE_COMMIT=\$(sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" rev-parse "origin/$BRANCH")
sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" reset --hard "origin/$BRANCH"
LOCAL_COMMIT=\$(sudo -u "$RUN_USER" git -C "$CHECKOUT_DIR" rev-parse HEAD)

if [[ "\$LOCAL_COMMIT" != "\$REMOTE_COMMIT" ]]; then
  "${RENDER_STALE_SCRIPT}" "mirror commit mismatch"
  exit 1
fi

rsync -a --delete \
  --exclude '.git' \
  --exclude '.DS_Store' \
  --exclude 'models' \
  "$CHECKOUT_DIR"/ "$PUBLIC_DIR"/

if [[ -d "$MODEL_SOURCE_DIR" ]]; then
  rsync -a --delete "$MODEL_SOURCE_DIR"/ "$PUBLIC_MODELS_DIR"/
else
  mkdir -p "$PUBLIC_MODELS_DIR"
fi

cat > "$PUBLIC_DIR/status.json" <<EOS
{"status":"ok","branch":"$BRANCH","commit":"\$LOCAL_COMMIT"}
EOS

printf '%s\n' "\$LOCAL_COMMIT" > "$PUBLIC_DIR/COMMIT"
EOF

chmod 755 "$SYNC_SCRIPT"

cat > "$STATUS_SCRIPT" <<EOF
#!/usr/bin/env bash
set -euo pipefail
curl -fsSL "http://${HTTP_BIND}:${HTTP_PORT}/status.json"
EOF

chmod 755 "$STATUS_SCRIPT"

"$RENDER_STALE_SCRIPT" "mirror not synced yet"

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
ExecStart=/usr/bin/python3 -m http.server $HTTP_PORT --bind $HTTP_BIND --directory $PUBLIC_DIR
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
echo "Repo checkout: $CHECKOUT_DIR"
echo "Published mirror: $PUBLIC_DIR"
echo "Published models: $PUBLIC_MODELS_DIR"
echo "Mirror status: $BIN_DIR/status.sh"
