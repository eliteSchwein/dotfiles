#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Greetd Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Greetd"
paru -S greetd greetd-dms-greeter-bin acl "${PACMAN_FLAGS[@]}"

log_info "Copy Greetd Configs"
sudo cp -af no-stow-root/etc/greetd/config.toml /etc/greetd/config.toml
sudo mkdir -p /var/lib/greeter/.cache/sysc-greet
sudo cp -af no-stow-root/var/lib/greeter/.cache/sysc-greet/preferences /var/lib/greeter/.cache/sysc-greet/preferences
sudo chown -R greeter:greeter /var/lib/greeter/.cache/sysc-greet

log_info "Configure DankGreeter Theme Sync"
sudo usermod -aG greeter "$USER"

setfacl -m u:greeter:x "$HOME"
setfacl -m u:greeter:x "$HOME/.config"
setfacl -m u:greeter:x "$HOME/.local"
setfacl -m u:greeter:x "$HOME/.cache"
setfacl -m u:greeter:x "$HOME/.local/state"

DMS_SYNC_DIRS=(
    "$HOME/.config/DankMaterialShell"
    "$HOME/.local/state/DankMaterialShell"
    "$HOME/.cache/quickshell"
)

for dir in "${DMS_SYNC_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        sudo chgrp -R greeter "$dir"
        sudo chmod -R g+rX "$dir"
    fi
done

sudo mkdir -p /var/cache/dms-greeter
sudo ln -sfn "$HOME/.config/DankMaterialShell/settings.json" /var/cache/dms-greeter/settings.json
sudo ln -sfn "$HOME/.local/state/DankMaterialShell/session.json" /var/cache/dms-greeter/session.json
sudo ln -sfn "$HOME/.cache/quickshell/dankshell/dms-colors.json" /var/cache/dms-greeter/colors.json

log_info "Enable Greetd"
sudo systemctl enable greetd

log_ok "Greetd Install: done"
