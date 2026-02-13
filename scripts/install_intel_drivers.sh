#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Intel GPU Setup (iGPU + Arc): starting"

PACMAN_FLAGS=(--noconfirm --needed)

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log_error "Missing required command: $1"
    exit 1
  }
}

has_intel_gpu() {
  # Detect Intel display controllers
  if command -v lspci >/dev/null 2>&1; then
    lspci -nn | grep -Eqi 'VGA|3D|Display' | grep -qi 'intel' && return 0
    # Also match vendor id 8086 on display class lines
    lspci -nn | grep -Eqi 'VGA|3D|Display' | grep -qi '\[8086:' && return 0
  fi

  # Fallback: loaded kernel drivers
  lsmod 2>/dev/null | grep -qE '^(i915|xe)\b' && return 0
  return 1
}

has_intel_arc() {
  # Best-effort: Arc GPUs usually show "Arc" or "DG2" in lspci
  command -v lspci >/dev/null 2>&1 || return 1
  lspci | grep -Ei 'VGA|3D|Display' | grep -Eqi 'Arc|DG2|Alchemist' && return 0
  return 1
}

is_legacy_intel_igpu() {
  # Rough heuristic for older gens that often need i965 VA-API driver (libva-intel-driver)
  # (Sandy/Ivy/Haswell are common culprits)
  command -v lspci >/dev/null 2>&1 || return 0
  lspci | grep -Ei 'VGA|3D|Display' | grep -Eqi \
    'Sandy|Ivy|Haswell|3rd Gen|2nd Gen|4th Gen|HD Graphics 2|HD Graphics 3|HD Graphics 4|HD Graphics 2500|HD Graphics 3000|HD Graphics 4000' \
    && return 0
  return 1
}

install_intel_stack() {
  require_cmd paru
  sudo -v

  log_info "Installing Intel GPU userspace stack (Mesa + Vulkan + VA-API)"
  # Mesa: OpenGL + core drivers
  # vulkan-intel: Intel ANV Vulkan driver (works for iGPU + Arc)
  # intel-media-driver: VA-API iHD driver (Broadwell+ and Arc)
  # libva-utils: vainfo (debug)
  # intel-gpu-tools: intel_gpu_top etc. (useful, optional but small)
  # libvdpau-va-gl: VDPAU->VAAPI bridge (helps some apps)
  paru -S \
    mesa lib32-mesa \
    vulkan-intel lib32-vulkan-intel opencl-mesa \
    intel-media-driver \
    libva-utils vulkan-tools \
    intel-gpu-tools \
    libvdpau-va-gl lib32-libvdpau-va-gl \
    "${PACMAN_FLAGS[@]}"

  # Legacy VA-API for older iGPUs (i965). Install only when we suspect legacy.
  if is_legacy_intel_igpu; then
    log_info "Legacy Intel iGPU detected; installing libva-intel-driver (i965 VA-API)"
    paru -S libva-intel-driver lib32-libva-intel-driver "${PACMAN_FLAGS[@]}"
  else
    log_info "Modern Intel GPU detected; skipping legacy libva-intel-driver"
  fi

  paru -S intel-compute-runtime "${PACMAN_FLAGS[@]}" || true

  log_ok "Intel userspace stack installed"
}

main() {
  if ! has_intel_gpu; then
    log_info "No Intel GPU detected; skipping Intel setup"
    log_ok "Intel GPU Setup: done (skipped)"
    exit 0
  fi

  if has_intel_arc; then
    log_info "Intel Arc GPU detected"
  else
    log_info "Intel iGPU detected"
  fi

  install_intel_stack

  log_ok "Intel GPU Setup (iGPU + Arc): done"
  log_info "Tip: verify VA-API with: vainfo"
  log_info "Tip: verify Vulkan with: vulkaninfo | head"
}

main
