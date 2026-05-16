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
    0x1002) vendor_name="AMD" ;;
    0x8086) vendor_name="Intel" ;;
    *) continue ;;
  esac

  found_gpu=true

  hwmon_glob=( "$dev"/hwmon/hwmon* )
  hwmon_dir="${hwmon_glob[0]:-}"

  if [[ -z "$hwmon_dir" || ! -d "$hwmon_dir" ]]; then
    echo "No hwmon directory for $(basename "$card"); skipping."
    continue
  fi

  if [[ "$vendor" == "0x1002" ]]; then
    cap_files=( "$hwmon_dir/power1_cap" )
  else
    # Intel Arc / Xe / i915
    # Use exact powerN_max files only. Avoid power1_max_interval.
    cap_files=()

    for f in "$hwmon_dir"/power[0-9]*_max; do
      [[ -e "$f" ]] || continue
      [[ "$f" =~ /power[0-9]+_max$ ]] || continue
      cap_files+=( "$f" )
    done
  fi

  if (( ${#cap_files[@]} == 0 )); then
    echo "No power cap file for $(basename "$card") ($vendor_name); skipping."
    continue
  fi

  for cap_file in "${cap_files[@]}"; do
    if [[ ! -f "$cap_file" ]]; then
      echo "No power cap file for $(basename "$card") ($vendor_name); skipping."
      continue
    fi

    if [[ ! -w "$cap_file" ]]; then
      echo "Power cap file is not writable: $cap_file"
      continue
    fi

    if [[ "$vendor" == "0x1002" ]]; then
      max_file="$hwmon_dir/power1_cap_max"
      min_file="$hwmon_dir/power1_cap_min"
    else
      num="${cap_file##*/power}"
      num="${num%%_max}"

      rated_file="$hwmon_dir/power${num}_rated_max"
      min_file="$hwmon_dir/power${num}_min"

      # Intel Arc usually has no real min file.
      # Use current writable powerN_max as fallback reference.
      max_file="$cap_file"
      [[ -f "$rated_file" ]] && max_file="$rated_file"
    fi

    cur_cap=$(< "$cap_file")
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
      *)
        echo "Invalid MODE: $MODE" >&2
        exit 1
        ;;
    esac

    echo "Card: $(basename "$card")"
    echo "  Vendor: $vendor_name"
    echo "  Current: $(( cur_cap / 1000000 )) W"
    (( max_cap > 0 )) && echo "  HW/ref max: $(( max_cap / 1000000 )) W"
    (( min_cap > 0 )) && echo "  HW min: $(( min_cap / 1000000 )) W"
    echo "  Mode: $MODE"
    echo "  New cap: $(( new_cap / 1000000 )) W -> $cap_file"

    echo "$new_cap" > "$cap_file"
  done
done

if ! $found_gpu; then
  echo "No AMD or Intel GPUs found under /sys/class/drm."
  exit 1
fi
