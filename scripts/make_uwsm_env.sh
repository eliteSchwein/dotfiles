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

# Delete env only if present
if [[ -e "$ENV_FILE" ]]; then
  log_info "Removing existing $ENV_FILE"
  rm -f "$ENV_FILE"
fi

# Copy dist -> env
if [[ ! -e "$ENV_DIST" ]]; then
  log_error "Missing template: $ENV_DIST"
  exit 1
fi

log_info "Copying $ENV_DIST -> $ENV_FILE"
cp "$ENV_DIST" "$ENV_FILE"

# Detect GPU vendors (VGA/3D/Display)
GPU_LINES="$(lspci | grep -Ei 'vga|3d|display' || true)"

HAS_NVIDIA=0
HAS_INTEL=0
HAS_AMD=0

if echo "$GPU_LINES" | grep -qi 'nvidia'; then
  HAS_NVIDIA=1
  log_info "Detected NVIDIA GPU"
fi

if echo "$GPU_LINES" | grep -qiE 'intel'; then
  HAS_INTEL=1
  log_info "Detected Intel GPU"
fi

if echo "$GPU_LINES" | grep -qiE 'amd|advanced micro devices|ati'; then
  HAS_AMD=1
  log_info "Detected AMD GPU"
fi

strip_unrequired_gpu_sections() {
  local file="$1"
  local tmp
  tmp="$(mktemp)"

  awk \
    -v has_nvidia="$HAS_NVIDIA" \
    -v has_intel="$HAS_INTEL" \
    -v has_amd="$HAS_AMD" '
    BEGIN {
      section = "keep"
    }

    /^# [[:alnum:]_ -]+ env[[:space:]]*$/ {
      if ($0 == "# amd gpu env") {
        section = (has_amd == 1 ? "keep" : "drop")
      } else if ($0 == "# intel gpu env") {
        section = (has_intel == 1 ? "keep" : "drop")
      } else if ($0 == "# nvidia gpu env") {
        section = (has_nvidia == 1 ? "keep" : "drop")
      } else {
        section = "keep"
      }
    }

    section == "keep" {
      print
    }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
}

log_info "Removing unrequired GPU sections from $ENV_FILE"
strip_unrequired_gpu_sections "$ENV_FILE"

log_ok "uwsm env: done"