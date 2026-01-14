#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "DMS Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Shell Packages"
paru -S dms-shell-bin qt5ct qt6ct-kde \
  cava wl-clipboard i2c-tools qt5-wayland qt6-wayland cliphist brightnessctl qt6-multimedia accountsservice \
  matugen-bin python-pywalfox "${PACMAN_FLAGS[@]}"

DMS_DIR=".config/DankMaterialShell"
CONF="$DMS_DIR/settings.json"
DIST="$DMS_DIR/settings.json.dist"

# Ensure we operate from home regardless of where the script is called
cd "$HOME"

if [[ -e "$CONF" ]]; then
  log_info "Removing existing $CONF"
  rm -f "$CONF"
fi

if [[ ! -e "$DIST" ]]; then
  log_error "Missing template: $DIST"
  exit 1
fi

log_info "Copying $DIST -> $CONF"
cp -f "$DIST" "$CONF"

log_info "Fetch current DMS"
dms plugins browse

# ---- Plugin install: only install if missing ----
log_info "Checking installed plugins"
plugins_list="$(dms plugins list 2>/dev/null || true)"

has_plugin_id() {
  local id="$1"
  # Match "ID: <id>" lines; tolerate spacing
  grep -Eq "^[[:space:]]*ID:[[:space:]]*$id([[:space:]]*)$" <<<"$plugins_list"
}

install_plugin_if_missing() {
  local id="$1"
  local name="$2"

  if has_plugin_id "$id"; then
    log_info "$name already installed (ID: $id); skipping"
  else
    log_info "Installing $name (ID: $id)"
    dms plugins install "$id"
  fi
}

install_plugin_if_missing "mediaPlayer"        "Desktop Media Player Plugin"
install_plugin_if_missing "dankDesktopWeather" "Weather Plugin"
install_plugin_if_missing "dankBatteryAlerts"  "Battery Alert Plugin"
install_plugin_if_missing "desktopCommand"     "Console Widget Plugin"

log_ok "DMS Install: done"
