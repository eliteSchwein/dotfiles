#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Power Profiles Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Power Profiles Daemon"
paru -S power-profiles-daemon power-profiles-hooks-fixed "${PACMAN_FLAGS[@]}"

log_info "Enable Power Profiles Daemon"
sudo systemctl enable --now power-profiles-daemon power-profiles-hooks

log_ok "Power Profiles Install: done"
