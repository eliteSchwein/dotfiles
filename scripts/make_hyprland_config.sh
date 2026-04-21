#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Hyprland config: starting"

HYPR_DIR=".config/hypr"
CONF="$HYPR_DIR/hyprland.conf"
DIST="$HYPR_DIR/hyprland.conf.dist"

mkdir -p "$HYPR_DIR"

# Delete conf only if present
if [[ -e "$CONF" ]]; then
  log_info "Removing existing $CONF"
  rm -f "$CONF"
fi

# Copy dist -> conf
if [[ ! -e "$DIST" ]]; then
  log_error "Missing template: $DIST"
  exit 1
fi

log_info "Copying $DIST -> $CONF"
cp -r "$DIST" "$CONF"

log_ok "Hyprland config: done"