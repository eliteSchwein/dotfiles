#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-balanced}"  # max|min|balanced
INTEL_CONF="/etc/power-profiles.d/intel-gpu-power.conf"

[[ "$EUID" -eq 0 ]] || {
  echo "This script must be run as root." >&2
  exit 1
}

case "$MODE" in
  max|min|balanced) ;;
  *)
    echo "Invalid mode: $MODE. Use: max|min|balanced" >&2
    exit 1
    ;;
esac

log() {
  echo "[gpu-power] $*"
}

get_intel_conf_value() {
  local pci_id="$1" wanted="$2"

  [[ -f "$INTEL_CONF" ]] || return 1

  awk -v pci="$pci_id" -v wanted="$wanted" '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }

    $1 == pci {
      if (wanted == "min") print $2
      if (wanted == "max") print $3
      exit
    }
  ' "$INTEL_CONF"
}

is_number() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

nvidia_power_cap() {
  local card="$1" dev="$2"
  local pci_id query cur_cap min_cap max_cap new_cap verify_cap

  if ! command -v nvidia-smi >/dev/null 2>&1; then
    log "NVIDIA GPU found at $(basename "$card"), but nvidia-smi is unavailable; skipping."
    return
  fi

  pci_id="$(basename "$(readlink -f "$dev")")"

  query="$(
    nvidia-smi \
      -i "$pci_id" \
      --query-gpu=power.limit,power.min_limit,power.max_limit \
      --format=csv,noheader,nounits \
      2>/dev/null || true
  )"

  if [[ -z "$query" ]]; then
    log "Could not query NVIDIA power limits for $pci_id; skipping."
    return
  fi

  IFS=',' read -r cur_cap min_cap max_cap <<< "$query"

  # Trim whitespace returned by nvidia-smi.
  cur_cap="${cur_cap//[[:space:]]/}"
  min_cap="${min_cap//[[:space:]]/}"
  max_cap="${max_cap//[[:space:]]/}"

  if ! is_number "$cur_cap" || ! is_number "$min_cap" || ! is_number "$max_cap"; then
    log "NVIDIA power limits are unavailable for $pci_id; skipping."
    return
  fi

  case "$MODE" in
    max)
      new_cap="$(awk -v max="$max_cap" 'BEGIN { printf "%.0f", max }')"
      ;;
    balanced)
      new_cap="$(
        awk -v max="$max_cap" -v min="$min_cap" '
          BEGIN {
            value = max * 0.80
            if (value < min)
              value = min
            printf "%.0f", value
          }
        '
      )"
      ;;
    min)
      new_cap="$(awk -v min="$min_cap" 'BEGIN { printf "%.0f", min }')"
      ;;
  esac

  log "Card: $(basename "$card")"
  log "Vendor: NVIDIA"
  log "PCI ID: $pci_id"
  log "Current: $cur_cap W"
  log "Max: $max_cap W"
  log "Min: $min_cap W"
  log "Mode: $MODE"
  log "New cap: $new_cap W -> nvidia-smi"

  if ! nvidia-smi -i "$pci_id" -pl "$new_cap" >/dev/null; then
    log "Failed to set NVIDIA power limit for $pci_id."
    return
  fi

  verify_cap="$(
    nvidia-smi \
      -i "$pci_id" \
      --query-gpu=power.limit \
      --format=csv,noheader,nounits \
      2>/dev/null || true
  )"
  verify_cap="${verify_cap//[[:space:]]/}"

  if is_number "$verify_cap"; then
    log "Verify cap after write: $verify_cap W"
  else
    log "Could not verify NVIDIA power limit after write."
  fi
}

sleep 2s

found_gpu=false

log "Mode: $MODE"
log "Intel config: $INTEL_CONF"
[[ -f "$INTEL_CONF" ]] && log "Intel config exists: yes" || log "Intel config exists: no"

for card in /sys/class/drm/card[0-9]*; do
  [[ -d "$card/device" && -f "$card/device/vendor" ]] || continue

  dev="$card/device"
  vendor=$(< "$dev/vendor")

  case "$vendor" in
    0x1002) vendor_name="AMD" ;;
    0x8086) vendor_name="Intel" ;;
    0x10de) vendor_name="NVIDIA" ;;
    *) continue ;;
  esac

  found_gpu=true

  if [[ "$vendor" == "0x10de" ]]; then
    nvidia_power_cap "$card" "$dev"
    continue
  fi

  hwmon_glob=( "$dev"/hwmon/hwmon* )
  hwmon_dir="${hwmon_glob[0]:-}"

  [[ -d "$hwmon_dir" ]] || {
    log "No hwmon directory for $(basename "$card"); skipping."
    continue
  }

  if [[ "$vendor" == "0x1002" ]]; then
    cap_files=( "$hwmon_dir/power1_cap" )
  else
    cap_files=()

    for f in "$hwmon_dir"/power[0-9]*_max; do
      [[ -e "$f" ]] || continue
      [[ "$f" =~ /power[0-9]+_max$ ]] || continue
      cap_files+=( "$f" )
    done
  fi

  for cap_file in "${cap_files[@]}"; do
    [[ -f "$cap_file" ]] || continue

    if [[ ! -w "$cap_file" ]]; then
      log "Not writable: $cap_file"
      continue
    fi

    cur_cap=$(< "$cap_file")
    max_cap=0
    min_cap=0
    pci_id=""

    if [[ "$vendor" == "0x1002" ]]; then
      [[ -f "$hwmon_dir/power1_cap_max" ]] && max_cap=$(< "$hwmon_dir/power1_cap_max")
      [[ -f "$hwmon_dir/power1_cap_min" ]] && min_cap=$(< "$hwmon_dir/power1_cap_min")
    else
      pci_id="$(basename "$(readlink -f "$dev")")"

      conf_min="$(get_intel_conf_value "$pci_id" min || true)"
      conf_max="$(get_intel_conf_value "$pci_id" max || true)"

      [[ "$conf_min" =~ ^[0-9]+$ ]] && min_cap="$conf_min"
      [[ "$conf_max" =~ ^[0-9]+$ ]] && max_cap="$conf_max"

      num="${cap_file##*/power}"
      num="${num%%_max}"
      rated_file="$hwmon_dir/power${num}_rated_max"

      if (( max_cap <= 0 )) && [[ -f "$rated_file" ]]; then
        max_cap=$(< "$rated_file")
      fi
    fi

    if (( max_cap <= 0 )); then
      log "No max cap for $(basename "$card"); skipping."
      continue
    fi

    case "$MODE" in
      max)
        new_cap="$max_cap"
        ;;
      balanced)
        new_cap=$(( max_cap * 80 / 100 ))
        ;;
      min)
        if (( min_cap > 0 )); then
          new_cap="$min_cap"
        else
          log "No min cap for $(basename "$card"); skipping."
          continue
        fi
        ;;
    esac

    log "Card: $(basename "$card")"
    log "Vendor: $vendor_name"
    [[ "$vendor" == "0x8086" ]] && log "PCI ID: $pci_id"
    log "Current: $(( cur_cap / 1000000 )) W"
    log "Max: $(( max_cap / 1000000 )) W"
    (( min_cap > 0 )) && log "Min: $(( min_cap / 1000000 )) W"
    log "Mode: $MODE"
    log "New cap: $(( new_cap / 1000000 )) W -> $cap_file"

    echo "$new_cap" > "$cap_file"

    verify_cap=$(< "$cap_file")
    log "Verify cap after write: $(( verify_cap / 1000000 )) W"
  done
done

if ! $found_gpu; then
  log "No AMD, Intel, or NVIDIA GPUs found under /sys/class/drm."
  exit 1
fi
