#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Greetd Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Greetd"
paru -S greetd greetd-tuigreet "${PACMAN_FLAGS[@]}"

log_info "Copy Greetd Config"
sudo cp -af no-stow-root/etc/greetd/config.toml /etc/greetd/config.toml

log_info "Enable Greetd"
sudo systemctl enable greetd

#source is https://github.com/apognu/tuigreet/issues/68#issuecomment-1586359960
log_info "Patch Greetd Service"
dir="/etc/systemd/system/greetd.service.d"
file="$dir/no_spam.conf"

sudo install -d -m 0755 "$dir"

sudo tee "$file" > /dev/null <<'EOF'
[Service]
Type=idle
StandardOutput=tty
# Without this errors will spam on screen
StandardError=journal
# Without these bootlogs will spam on screen
TTYReset=true
TTYVHangup=true
TTYVTDisallocate=true
EOF

sudo systemctl daemon-reload
sudo systemctl restart greetd

log_ok "Greetd Install: done"