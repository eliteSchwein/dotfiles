#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "AMD (AMF) Setup: starting"

PACMAN_FLAGS=(--noconfirm --needed)

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log_error "Missing required command: $1"
    exit 1
  }
}

has_amd_gpu() {
  if command -v lspci >/dev/null 2>&1; then
    # Match AMD/ATI display controllers
    lspci -nn | grep -Eqi 'VGA|3D|Display' | grep -Eqi 'AMD|ATI' && return 0
  fi
  # Fallback: loaded module
  lsmod 2>/dev/null | grep -qE '^(amdgpu)\b' && return 0
  return 1
}

install_amd_stack() {
  require_cmd paru
  sudo -v

  log_info "Installing AMD GPU userspace stack (Mesa/VA-API/Vulkan)"
  paru -S \
    vulkan-radeon vulkan-tools \
    mesa-utils libva-utils opencl-mesa \
    lib32-mesa \
    egl-wayland egl-gbm \
    amdgpu_top rocm-smi-lib amdsmi \
    amf-amdgpu-pro "${PACMAN_FLAGS[@]}"

  log_ok "AMD userspace stack installed"
}

install_amd_hibernate() {
  require_cmd paru
  sudo -v
  log_info "Installing AMD GPU userspace hibernate service"
  paru -S \
    memreserver-git "${PACMAN_FLAGS[@]}"

  sudo systemctl enable --now memreserver

  log_ok "AMD userspace hibernate service installed"
}

main() {
  if ! has_amd_gpu; then
    log_info "No AMD GPU detected; skipping AMD setup"
    log_ok "AMD (AMF) Setup: done (skipped)"
    exit 0
  fi

  log_info "AMD GPU detected; installing Mesa/VA-API/Vulkan stack"
  install_amd_stack
  install_amd_hibernate

  log_ok "AMD (AMF) Setup: done"
}

main
