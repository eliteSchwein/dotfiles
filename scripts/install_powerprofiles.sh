#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Power Profiles Install: starting"

log_info "Detach existing dotfile links from Power Profiles Folder"
if [[ -L /etc/power-profiles.d ]]; then
    # Never operate through a directory symlink: unlink the symlink itself.
    sudo rm -f -- /etc/power-profiles.d
elif [[ -d /etc/power-profiles.d ]]; then
    # Remove symlinks only. Keep real directories/files intact and, most
    # importantly, never recursively delete through paths managed by Stow.
    while IFS= read -r -d '' link; do
        log_info "Unlink existing Power Profiles symlink: $link"
        sudo rm -f -- "$link"
    done < <(sudo find /etc/power-profiles.d -type l -print0)
fi

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Power Profiles Daemon"
paru -S power-profiles-daemon power-profiles-hooks-fixed "${PACMAN_FLAGS[@]}"

log_info "Enable Power Profiles Daemon"
sudo systemctl enable --now power-profiles-daemon power-profiles-hooks

log_ok "Power Profiles Install: done"
