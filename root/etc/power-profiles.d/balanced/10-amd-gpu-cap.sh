#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-balanced}"  # max|min|balanced

[[ "$EUID" -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

set_cap() {
  local card="$1" vendor="$2" cap_file="$3" max_file="${4:-}" min_file="${5:-}"

  [[ -w "$cap_file" ]] || {
    echo "Not writable: $cap_file"
    return
  }

  local cur_cap max_cap min_cap new_cap
  cur_cap=$(< "$cap_file")
  max_cap=0
  min_cap=0

  [[ -n "$max_file" && -f "$max_file" ]] && max_cap=$(< "$max_file")
  [[ -n "$min_file" && -f "$min_file" ]] && min_cap=$(< "$min_file")

  case "$MODE" in
    max)
      if (( max_cap > 0 )); then
        new_cap="$max_cap"
      else
        echo "No max value for $(basename "$card"); skipping."
        return
      fi
      ;;
    min)
      if (( min_cap > 0 )); then
        new_cap="$min_cap"
      elif (( max_cap > 0 )); then
        new_cap=$(( max_cap * 50 / 100 ))
      else
        echo "No min/max value for $(basename "$card"); skipping."
        return
      fi
      ;;
    balanced)
      if (( max_cap > 0 && min_cap > 0 )); then
        new_cap=$(( min_cap + (max_cap - min_cap) / 2 ))
      elif (( max_cap > 0 )); then
        new_cap=$(( max_cap * 80 / 100 ))
      else
        echo "No max value for $(basename "$card"); skipping."
        return
      fi
      ;;
    *)
      echo "Invalid mode: $MODE. Use: max|min|balanced" >&2
      exit 1
      ;;
  esac

  echo "Card: $(basename "$card")"
  echo "  Vendor: $vendor"
  echo "  Current: $(( cur_cap / 1000000 )) W"
  (( max_cap > 0 )) && echo "  Max/ref: $(( max_cap / 1000000 )) W"
  (( min_cap > 0 )) && echo "  Min: $(( min_cap / 1000000 )) W"
  echo "  Mode: $MODE"
  echo "  New cap: $(( new_cap / 1000000 )) W -> $cap_file"

  echo "$new_cap" > "$cap_file"
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
    echo "No hwmon for $(basename "$card"); skipping."
    continue
  }

  if [[ "$vendor" == "0x1002" ]]; then
    # AMD amdgpu
    set_cap "$card" "$vendor_name" \
      "$hwmon_dir/power1_cap" \
      "$hwmon_dir/power1_cap_max" \
      "$hwmon_dir/power1_cap_min"
  else
    # Intel Arc / Xe / i915
    # Intel Arc usually exposes the writable limit directly as powerN_max.
    # Avoid matching files like power1_max_interval.
    found_intel_cap=false

    for cap_file in "$hwmon_dir"/power[0-9]*_max; do
      [[ -e "$cap_file" ]] || continue
      [[ "$cap_file" =~ /power[0-9]+_max$ ]] || continue
      [[ -w "$cap_file" ]] || continue

      # Use current powerN_max as reference.
      # balanced = 80% of current limit
      # min = 50% of current limit
      # max = current limit unless no higher rated file exists
      num="${cap_file##*/power}"
      num="${num%%_max}"

      rated_file="$hwmon_dir/power${num}_rated_max"

      if [[ "$MODE" == "max" && -f "$rated_file" ]]; then
        set_cap "$card" "$vendor_name" "$cap_file" "$rated_file" ""
      else
        set_cap "$card" "$vendor_name" "$cap_file" "$cap_file" ""
      fi

      found_intel_cap=true
    done

    $found_intel_cap || echo "No writable Intel powerN_max for $(basename "$card"); skipping."
  fi
done

if ! $found_gpu; then
  echo "No AMD or Intel GPUs found under /sys/class/drm."
  exit 1
fi
