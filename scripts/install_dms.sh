#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "DMS Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Shell Packages"
paru -S dms-shell-bin qt5ct qt6ct-kde  \
  cava wl-clipboard i2c-tools qt5-wayland qt6-wayland cliphist brightnessctl qt6-multimedia accountsservice \
  matugen-bin python-pywalfox quickshell-git "${PACMAN_FLAGS[@]}"

cd .config/DankMaterialShell
DMS_DIR=".config/DankMaterialShell"
CONF="$DMS_DIR/settings.json"
DIST="$DMS_DIR/settings.json.dist"

if [[ -e "$CONF" ]]; then
  log_info "Removing existing $CONF"
  rm -f "$CONF"
fi

if [[ ! -e "$DIST" ]]; then
  log_error "Missing template: $DIST"
  exit 1
fi

log_info "Copying $DIST -> $CONF"
cp -r "$DIST" "$CONF"

log_info "Fetch current DMS"
dms plugin browse

log_info "Install Desktop Media Player Plugin"
dms plugin install mediaPlayer

log_info "Install Weather Plugin"
dms plugin install dankDesktopWeather

log_info "Install Battery Alert Plugin"
dms plugin install dankBatteryAlerts

log_info "Install Console Widget Plugin"
dms plugin install desktopCommand

log_ok "DMS Install: done"
