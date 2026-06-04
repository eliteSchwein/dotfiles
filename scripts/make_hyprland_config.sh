#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Hyprland Lua config: starting"

HYPR_DIR=".config/hypr"
CONF="$HYPR_DIR/hyprland.lua"
DIST="$HYPR_DIR/hyprland.lua.dist"
OLD_CONF="$HYPR_DIR/hyprland.conf"
OLD_DIST="$HYPR_DIR/hyprland.conf.dist"

mkdir -p "$HYPR_DIR"

# Remove old generated configs if present
if [[ -e "$CONF" ]]; then
  log_info "Removing existing $CONF"
  rm -f "$CONF"
fi

if [[ -e "$OLD_CONF" ]]; then
  log_info "Removing old $OLD_CONF"
  rm -f "$OLD_CONF"
fi

# Copy Lua dist -> active Lua config
if [[ ! -e "$DIST" ]]; then
  log_error "Missing template: $DIST"
  exit 1
fi

log_info "Copying $DIST -> $CONF"
cp -r "$DIST" "$CONF"

# Keep old dist untouched, but warn when it is still around
if [[ -e "$OLD_DIST" ]]; then
  log_info "Old template still present: $OLD_DIST"
fi

log_ok "Hyprland Lua config: done"
