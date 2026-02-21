#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "DMS Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Shell Packages"
paru -S dms-shell-bin qt5ct khal qt6ct-kde \
  cava wl-clipboard i2c-tools qt5-wayland qt6-wayland cliphist brightnessctl qt6-multimedia accountsservice \
  matugen python-pywalfox "${PACMAN_FLAGS[@]}"

DMS_DIR="dotfiles/.config/DankMaterialShell"
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

log_info "Make empty DMS Hyprland settings"

HYPR_DMS_DIR=".config/hypr/dms"

# Ensure directory exists
if [[ -d "$HYPR_DMS_DIR" ]]; then
  log_info "Directory exists: $HYPR_DMS_DIR"
else
  log_info "Creating directory: $HYPR_DMS_DIR"
  mkdir -p "$HYPR_DMS_DIR"
fi

ensure_file() {
  local f="$1"
  if [[ -e "$f" ]]; then
    log_info "File exists: $f (leaving as-is)"
  else
    log_info "Creating empty file: $f"
    : > "$f"   # create empty file
  fi
}

ensure_file "$HYPR_DMS_DIR/outputs.conf"
ensure_file "$HYPR_DMS_DIR/cursor.conf"
ensure_file "$HYPR_DMS_DIR/colors.conf"
ensure_file "$HYPR_DMS_DIR/layout.conf"

log_info "Generate initial DMS Session"

mkdir -p "$HOME/.local/state/DankMaterialShell"

cat > "$HOME/.local/state/DankMaterialShell/session.json" <<EOF
{
  "wallpaperPath": "$HOME/wallpapers/HighResScreenShot_2023-11-16_22-23-34.png",
  "wallpaperTransition": "stripes",
  "perModeWallpaper": false,
  "isLightMode": false
}
EOF



log_ok "DMS Install: done"
