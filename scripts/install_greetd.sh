#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Greetd Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Greetd"
paru -S greetd greetd-dms-greeter-git acl "${PACMAN_FLAGS[@]}"

log_info "Copy Greetd Configs"
sudo cp -af no-stow-root/etc/greetd/config.toml /etc/greetd/config.toml

log_info "Sync DankMaterialShell Greeter Configuration"
DMS_PRIVESC=sudo dms-greeter sync

log_info "Enable Greetd"
sudo systemctl enable greetd

log_ok "Greetd Install: done"