#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Greetd Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Greetd"
paru -S greetd sysc-greet-hyprland "${PACMAN_FLAGS[@]}"

log_info "Copy Greetd Configs"
sudo cp -af no-stow-root/etc/greetd/config.toml /etc/greetd/config.toml
sudo mkdir -p /var/lib/greeter/.cache
sudo cp -af no-stow-root/var/lib/greet/.cache/sysc-greeter /var/lib/greeter/.cache/sysc-greet
sudo chown -R greeter:greeter /var/lib/greeter/.cache/sysc-greet

log_info "Enable Greetd"
sudo systemctl enable greetd

log_ok "Greetd Install: done"
