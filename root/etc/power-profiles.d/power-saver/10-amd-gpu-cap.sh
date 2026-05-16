#!/usr/bin/env bash
set -euo pipefail

MODE="min"  # max|min|balanced
INTEL_CONF="/etc/power-profiles.d/intel-gpu-power.conf"

[[ "$EUID" -eq 0 ]] || {
  echo "This script must be run as root." >&2
  exit 1
}

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

found_gpu=false

log "Mode: $MODE"
log "Intel config: $INTEL_CONF"

if [[ -f "$INTEL_CONF" ]]; then
  log "Intel config exists: yes"
else
  log "Intel config exists: no"
fi

for card in /sys/class/drm/card[0-9]*; do
  [[ -d "$card/device" && -f "$card/device/vendor" ]] || continue

  dev="$card/device"
  vendor=$(< "$dev/vendor")

  case "$vendor" in
    0x1002) vendor_name="AMD" ;;
    0x8086) vendor_name="Intel" ;;
    *) continue ;;
  esac

  found_gpu=true

  log "----------------------------------------"
  log "Card: $(basename "$card")"
  log "Vendor: $vendor_name ($vendor)"
  log "Device path: $dev"
  log "Resolved PCI path: $(readlink -f "$dev")"

  hwmon_glob=( "$dev"/hwmon/hwmon* )
  hwmon_dir="${hwmon_glob[0]:-}"

  if [[ ! -d "$hwmon_dir" ]]; then
    log "No hwmon directory for $(basename "$card"); skipping."
    continue
  fi

  log "hwmon dir: $hwmon_dir"

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

  if (( ${#cap_files[@]} == 0 )); then
    log "No power cap files found for $(basename "$card") ($vendor_name); skipping."
    continue
  fi

  for cap_file in "${cap_files[@]}"; do
    [[ -f "$cap_file" ]] || {
      log "Cap file does not exist: $cap_file"
      continue
    }

    [[ -w "$cap_file" ]] || {
      log "Not writable: $cap_file"
      continue
    }

    cur_cap=$(< "$cap_file")
    max_cap=0
    min_cap=0

    if [[ "$vendor" == "0x1002" ]]; then
      max_file="$hwmon_dir/power1_cap_max"
      min_file="$hwmon_dir/power1_cap_min"

      [[ -f "$max_file" ]] && max_cap=$(< "$max_file")
      [[ -f "$min_file" ]] && min_cap=$(< "$min_file")
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
      *)
        log "Invalid MODE: $MODE"
        exit 1
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
  log "No AMD or Intel GPUs found under /sys/class/drm."
  exit 1
fi
