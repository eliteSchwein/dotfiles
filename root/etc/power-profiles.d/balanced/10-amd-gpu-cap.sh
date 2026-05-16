#!/usr/bin/env bash
set -euo pipefail

MODE="balanced"  # max|min|balanced
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
