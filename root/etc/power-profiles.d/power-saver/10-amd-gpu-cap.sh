#!/usr/bin/env bash
set -euo pipefail

MODE="min"  # max|min|balanced

if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

found_gpu=false

for card in /sys/class/drm/card[0-9]*; do
  [[ -d "$card/device" ]] || continue
  dev="$card/device"

  [[ -f "$dev/vendor" ]] || continue
  vendor=$(< "$dev/vendor")

  case "$vendor" in
    0x1002)
      vendor_name="AMD"
      ;;
    0x8086)
      vendor_name="Intel"
      ;;
    *)
      continue
      ;;
  esac

  found_gpu=true

  hwmon_glob=( "$dev"/hwmon/hwmon* )
  hwmon_dir="${hwmon_glob[0]:-}"
  if [[ -z "${hwmon_dir}" || ! -d "$hwmon_dir" ]]; then
    echo "No hwmon directory for $(basename "$card"); skipping."
    continue
  fi

  if [[ "$vendor" == "0x1002" ]]; then
    cap_file="$hwmon_dir/power1_cap"
    max_file="$hwmon_dir/power1_cap_max"
    min_file="$hwmon_dir/power1_cap_min"
  else
    cap_file="$hwmon_dir/power1_max"
    max_file="$hwmon_dir/power1_rated_max"
    min_file="$hwmon_dir/power1_min"

    [[ -f "$max_file" ]] || max_file="$cap_file"
  fi

  if [[ ! -f "$cap_file" ]]; then
    echo "No power cap file for $(basename "$card") ($vendor_name); skipping."
    continue
  fi

  max_cap=0
  min_cap=0
  [[ -f "$max_file" ]] && max_cap=$(< "$max_file")
  [[ -f "$min_file" ]] && min_cap=$(< "$min_file")

  new_cap=0

  case "$MODE" in
    min)
      if (( min_cap > 0 )); then
        new_cap=$min_cap
      elif (( max_cap > 0 )); then
        new_cap=$(( max_cap / 4 ))
      else
        echo "No min/max power cap for $(basename "$card"); skipping."
        continue
      fi
      ;;
  esac

  echo "Card: $(basename "$card")"
  echo "  Vendor: $vendor_name"
  (( max_cap > 0 )) && echo "  HW max: $(( max_cap / 1000000 )) W"
  (( min_cap > 0 )) && echo "  HW min: $(( min_cap / 1000000 )) W"
  echo "  Mode: $MODE"
  echo "  New cap: $(( new_cap / 1000000 )) W -> $cap_file"

  echo "$new_cap" > "$cap_file"
done

if ! $found_gpu; then
  echo "No AMD or Intel GPUs found under /sys/class/drm."
  exit 1
fi