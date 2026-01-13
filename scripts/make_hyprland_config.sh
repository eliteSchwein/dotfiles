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

# Copy dist -> conf (do NOT delete dist)
if [[ ! -e "$DIST" ]]; then
  log_error "Missing template: $DIST"
  exit 1
fi

log_info "Copying $DIST -> $CONF"
cp -r "$DIST" "$CONF"

enable_marker() {
  local marker="$1" file="$2"
  # Remove leading marker token from lines like:
  #   #NVIDIAGPU something...
  sed -i -E "s|^([[:space:]]*)${marker}[[:space:]]*|\\1|g" "$file"
}

# Detect GPU vendors (VGA/3D/Display)
GPU_LINES="$(lspci | grep -Ei 'vga|3d|display' || true)"

if echo "$GPU_LINES" | grep -qi 'nvidia'; then
  log_info "Detected NVIDIA GPU -> enabling #NVIDIAGPU lines"
  enable_marker '#NVIDIAGPU' "$CONF"
fi

if echo "$GPU_LINES" | grep -qiE 'intel'; then
  log_info "Detected Intel GPU -> enabling #INTELGPU lines"
  enable_marker '#INTELGPU' "$CONF"
fi

if echo "$GPU_LINES" | grep -qiE 'amd|advanced micro devices|ati'; then
  log_info "Detected AMD GPU -> enabling #AMDGPU lines"
  enable_marker '#AMDGPU' "$CONF"
fi

log_ok "Hyprland config: done"
