#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Old Packages Removal: starting"

PACMAN_FLAGS=(--noconfirm)

log_info "Remove old packages (only if installed)"
to_remove=(hypridle hyprlock bun-bin greetd-dms-greeter-git thunar gvfs gvfs-afc gvfs-mtp gvfs-smb clipse-bin)

installed=()
for p in "${to_remove[@]}"; do
  if pacman -Qq "$p" >/dev/null 2>&1; then
    installed+=("$p")
  else
    log_info "Package not installed; skipping: $p"
  fi
done

if ((${#installed[@]})); then
  paru -Rns "${installed[@]}" "${PACMAN_FLAGS[@]}"
  log_ok "Removed packages: ${installed[*]}"
else
  log_info "No matching packages installed; nothing to remove."
fi

log_ok "Old Packages Removal: done"
