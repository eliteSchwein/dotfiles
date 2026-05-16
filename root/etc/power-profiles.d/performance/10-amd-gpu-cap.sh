#!/usr/bin/env bash
set -euo pipefail

MODE="max"  # max|min|balanced
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
  log "Intel config content:"
  sed 's/^/[gpu-power]   /' "$INTEL_CONF"
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
  log "Detected PCI ID: $(basename "$(readlink -f "$dev")")"

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
      [[ "$f" =~ /power[0-9]+_max$ ]] || {
        log "Ignoring non-cap Intel file: $f"
        continue
      }
      cap_files+=( "$f" )
    done
  fi

  if (( ${#cap_files[@]} == 0 )); then
    log "No cap files found for $(basename "$card") ($vendor_name); skipping."
    continue
  fi

  log "Cap files:"
  for f in "${cap_files[@]}"; do
    log "  $f"
  done

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

    log "Processing cap file: $cap_file"
    log "Current raw cap: $cur_cap"
    log "Current cap: $(( cur_cap / 1000000 )) W"

    if [[ "$vendor" == "0x1002" ]]; then
      max_file="$hwmon_dir/power1_cap_max"
      min_file="$hwmon_dir/power1_cap_min"

      log "AMD max file: $max_file"
      log "AMD min file: $min_file"

      [[ -f "$max_file" ]] && max_cap=$(< "$max_file")
      [[ -f "$min_file" ]] && min_cap=$(< "$min_file")
    else
      pci_id="$(basename "$(readlink -f "$dev")")"

      log "Looking up Intel config for PCI ID: $pci_id"

      conf_min="$(get_intel_conf_value "$pci_id" min || true)"
      conf_max="$(get_intel_conf_value "$pci_id" max || true)"

      log "Config min raw: ${conf_min:-<empty>}"
      log "Config max raw: ${conf_max:-<empty>}"

      if [[ "$conf_min" =~ ^[0-9]+$ ]]; then
        min_cap="$conf_min"
        log "Using config min: $min_cap / $(( min_cap / 1000000 )) W"
      else
        log "Config min invalid or missing."
      fi

      if [[ "$conf_max" =~ ^[0-9]+$ ]]; then
        max_cap="$conf_max"
        log "Using config max: $max_cap / $(( max_cap / 1000000 )) W"
      else
        log "Config max invalid or missing."
      fi

      num="${cap_file##*/power}"
      num="${num%%_max}"
      rated_file="$hwmon_dir/power${num}_rated_max"

      log "Intel power index: $num"
      log "Intel rated max file: $rated_file"

      if [[ -f "$rated_file" ]]; then
        rated_cap=$(< "$rated_file")
        log "Intel rated max raw: $rated_cap"
        log "Intel rated max: $(( rated_cap / 1000000 )) W"
      else
        log "Intel rated max file missing."
      fi

      if (( max_cap <= 0 )) && [[ -f "$rated_file" ]]; then
        max_cap=$(< "$rated_file")
        log "Fallback: using rated max as max_cap: $max_cap / $(( max_cap / 1000000 )) W"
      fi
    fi

    log "Final min_cap raw: $min_cap"
    log "Final max_cap raw: $max_cap"

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

    log "Selected mode: $MODE"
    log "New cap raw: $new_cap"
    log "New cap: $(( new_cap / 1000000 )) W"
    log "Writing: echo $new_cap > $cap_file"

    echo "$new_cap" > "$cap_file"

    verify_cap=$(< "$cap_file")
    log "Verify raw cap after write: $verify_cap"
    log "Verify cap after write: $(( verify_cap / 1000000 )) W"
  done
done

if ! $found_gpu; then
  log "No AMD or Intel GPUs found under /sys/class/drm."
  exit 1
fi#!/usr/bin/env bash
set -euo pipefail

MODE="max"  # max|min|balanced
INTEL_CONF="/etc/power-profiles.d/intel-gpu-power.conf"

[[ "$EUID" -eq 0 ]] || {
  echo "This script must be run as root." >&2
  exit 1
}

get_intel_conf_value() {
  local pci_id="$1" wanted="$2"

  [[ -f "$INTEL_CONF" ]] || return 1

  awk -v pci="$pci_id" -v wanted="$wanted" '
    $1 == pci {
      if (wanted == "min") print $2
      if (wanted == "max") print $3
    }
  ' "$INTEL_CONF"
}

found_gpu=false

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

  hwmon_glob=( "$dev"/hwmon/hwmon* )
  hwmon_dir="${hwmon_glob[0]:-}"

  [[ -d "$hwmon_dir" ]] || {
    echo "No hwmon directory for $(basename "$card"); skipping."
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
    [[ -w "$cap_file" ]] || {
      echo "Not writable: $cap_file"
      continue
    }

    cur_cap=$(< "$cap_file")
    max_cap=0
    min_cap=0

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
      echo "No max cap for $(basename "$card"); skipping."
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
          echo "No min cap for $(basename "$card"); skipping."
          continue
        fi
        ;;
      *)
        echo "Invalid MODE: $MODE" >&2
        exit 1
        ;;
    esac

    echo "Card: $(basename "$card")"
    echo "  Vendor: $vendor_name"
    [[ "$vendor" == "0x8086" ]] && echo "  PCI ID: $pci_id"
    echo "  Current: $(( cur_cap / 1000000 )) W"
    echo "  Max: $(( max_cap / 1000000 )) W"
    (( min_cap > 0 )) && echo "  Min: $(( min_cap / 1000000 )) W"
    echo "  Mode: $MODE"
    echo "  New cap: $(( new_cap / 1000000 )) W -> $cap_file"

    echo "$new_cap" > "$cap_file"
  done
done

if ! $found_gpu; then
  echo "No AMD or Intel GPUs found under /sys/class/drm."
  exit 1
fi
