#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "uwsm env: starting"

UWSM_DIR=".config/uwsm"
ENV_FILE="$UWSM_DIR/env"
ENV_DIST="$UWSM_DIR/env.dist"

mkdir -p "$UWSM_DIR"

if [[ ! -e "$ENV_DIST" ]]; then
  log_error "Missing template: $ENV_DIST"
  exit 1
fi

if [[ -e "$ENV_FILE" ]]; then
  log_info "Removing existing $ENV_FILE"
  rm -f "$ENV_FILE"
fi

log_info "Copying $ENV_DIST -> $ENV_FILE"
cp "$ENV_DIST" "$ENV_FILE"

GPU_LINES="$(lspci -Dnn 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller|Display controller' || true)"

# Keep this in sync with gpu.lua:
# NVIDIA dGPU -> AMD dGPU -> Intel Arc -> Intel iGPU.
main_gpu() {
  local nvidia amd intel_arc intel

  nvidia="$(printf '%s\n' "$GPU_LINES" | grep -Ei 'NVIDIA|\[10de:' | awk '{print $1}' | head -n1 || true)"
  amd="$(printf '%s\n' "$GPU_LINES" | grep -Ei 'AMD|Advanced Micro Devices|ATI|\[1002:' | awk '{print $1}' | head -n1 || true)"
  intel_arc="$(printf '%s\n' "$GPU_LINES" | grep -Ei 'Intel|\[8086:' | grep -Ei 'Arc|DG2|Alchemist|Battlemage|BMG' | awk '{print $1}' | head -n1 || true)"
  intel="$(printf '%s\n' "$GPU_LINES" | grep -Ei 'Intel|\[8086:' | awk '{print $1}' | head -n1 || true)"

  if [[ -n "$nvidia" ]]; then
    printf 'nvidia|%s\n' "$nvidia"
  elif [[ -n "$amd" ]]; then
    printf 'amd|%s\n' "$amd"
  elif [[ -n "$intel_arc" ]]; then
    printf 'intel|%s\n' "$intel_arc"
  elif [[ -n "$intel" ]]; then
    printf 'intel|%s\n' "$intel"
  fi
}

render_node_for_pci() {
  local pci="$1" node

  for node in "/sys/bus/pci/devices/$pci/drm/"renderD*; do
    [[ -e "$node" ]] || continue
    printf '/dev/dri/%s\n' "$(basename "$node")"
    return 0
  done

  return 1
}

# env.dist contains one section per GPU vendor. Remove every GPU section except
# the one belonging to the selected main GPU, so conflicting Mesa/NVIDIA/VA-API
# variables never reach the UWSM session.
strip_non_main_gpu_envs() {
  local keep_vendor="$1"
  local file="$2"
  local tmp
  tmp="$(mktemp)"

  awk -v keep_vendor="$keep_vendor" '
    BEGIN { gpu_section = "" }

    /^# amd gpu env[[:space:]]*$/ {
      gpu_section = "amd"
      if (gpu_section == keep_vendor) print
      next
    }

    /^# intel gpu env[[:space:]]*$/ {
      gpu_section = "intel"
      if (gpu_section == keep_vendor) print
      next
    }

    /^# nvidia gpu env[[:space:]]*$/ {
      gpu_section = "nvidia"
      if (gpu_section == keep_vendor) print
      next
    }

    /^# [[:alnum:]_ -]+ env[[:space:]]*$/ {
      gpu_section = ""
      print
      next
    }

    gpu_section == "" || gpu_section == keep_vendor {
      print
    }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
}

MAIN_GPU="$(main_gpu || true)"

if [[ -n "$MAIN_GPU" ]]; then
  MAIN_VENDOR="${MAIN_GPU%%|*}"
  MAIN_PCI="${MAIN_GPU#*|}"
  MAIN_RENDER_NODE="$(render_node_for_pci "$MAIN_PCI" || true)"

  log_info "Main GPU: $MAIN_VENDOR ($MAIN_PCI${MAIN_RENDER_NODE:+, $MAIN_RENDER_NODE})"

  strip_non_main_gpu_envs "$MAIN_VENDOR" "$ENV_FILE"

  if [[ -n "$MAIN_RENDER_NODE" ]]; then
    sed -i "s|__PREFERRED_RENDER_NODE__|$MAIN_RENDER_NODE|g" "$ENV_FILE"
  else
    log_warn "Could not resolve render node for $MAIN_PCI; removing WLR_RENDER_DRM_DEVICE"
    sed -i '/^export WLR_RENDER_DRM_DEVICE=__PREFERRED_RENDER_NODE__$/d' "$ENV_FILE"
  fi
else
  log_warn "No supported GPU detected; stripping all GPU-specific environment variables"
  strip_non_main_gpu_envs "none" "$ENV_FILE"
fi

log_ok "uwsm env: done"
