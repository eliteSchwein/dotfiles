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

log_info "Patch Greetd Service"
dir="/etc/systemd/system/greetd.service.d"

sudo install -d -m 0755 "$dir"

sudo tee "$dir/quite.conf" > /dev/null <<'EOF'
[Unit]
After=getty@tty2.service

[Service]
Type=idle
StandardInput=tty
TTYPath=/dev/tty2
TTYReset=yes
TTYVHangup=yes
EOF

sudo tee "$dir/stfu.conf" > /dev/null <<'EOF'
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

log_ok "Greetd Install: done"