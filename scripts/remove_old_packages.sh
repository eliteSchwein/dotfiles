#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Old Packages Removal: starting"

PACMAN_FLAGS=(--noconfirm)

log_info "Remove old packages"
paru -Rns \
  hypridle hyprlock greetd-tuigreet "${PACMAN_FLAGS[@]}"

log_ok "Old Packages Removal: done"
