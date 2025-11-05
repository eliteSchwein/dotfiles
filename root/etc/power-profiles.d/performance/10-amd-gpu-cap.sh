#!/usr/bin/env bash
set -euo pipefail

MODE="max"  # max|min|balanced

if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

found_amd=false

for card in /sys/class/drm/card[0-9]*; do
  [[ -d "$card/device" ]] || continue
  dev="$card/device"

  # Check vendor (AMD = 0x1002)
  [[ -f "$dev/vendor" ]] || continue
  vendor=$(< "$dev/vendor")
  [[ "$vendor" == "0x1002" ]] || continue

  found_amd=true

  hwmon_glob=( "$dev"/hwmon/hwmon* )
  hwmon_dir="${hwmon_glob[0]:-}"
  if [[ -z "${hwmon_dir}" || ! -d "$hwmon_dir" ]]; then
    echo "No hwmon directory for $(basename "$card"); skipping."
    continue
  fi

  cap_file="$hwmon_dir/power1_cap"
  max_file="$hwmon_dir/power1_cap_max"
  min_file="$hwmon_dir/power1_cap_min"

  if [[ ! -f "$cap_file" ]]; then
    echo "No power1_cap for $(basename "$card"); skipping."
    continue
  fi

  max_cap=0
  min_cap=0
  [[ -f "$max_file" ]] && max_cap=$(< "$max_file")
  [[ -f "$min_file" ]] && min_cap=$(< "$min_file")

  new_cap=0

  case "$MODE" in
    max)
      if (( max_cap > 0 )); then
        new_cap=$max_cap
      else
        echo "No power1_cap_max for $(basename "$card"); skipping."
        continue
      fi
      ;;
  esac

  echo "Card: $(basename "$card")"
  (( max_cap > 0 )) && echo "  HW max: $(( max_cap / 1000000 )) W"
  (( min_cap > 0 )) && echo "  HW min: $(( min_cap / 1000000 )) W"
  echo "  Mode: $MODE"
  echo "  New cap: $(( new_cap / 1000000 )) W -> $cap_file"

  echo "$new_cap" > "$cap_file"
done

if ! $found_amd; then
  echo "No AMD GPUs (vendor 0x1002) found under /sys/class/drm."
  exit 1
fi
