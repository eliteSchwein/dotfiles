#!/usr/bin/env bash
set -euo pipefail

# --- abort if already locked (hyprlock running) ------------------------------
if pgrep -x hyprlock >/dev/null 2>&1; then
  # already locked, nothing to do
  exit 0
fi

CONF="$HOME/.config/hypr/hyprlock.conf"

# --- outputs via hyprctl ---
mapfile -t outputs < <(hyprctl -j monitors | jq -r '.[].name')

# --- build per-monitor background blocks ---
block=""
for output in "${outputs[@]}"; do
  block+=$'background {\n'
  block+=$"    monitor = ${output}\n"
  block+=$"    path = /tmp/${output}-lockscreen.png\n"
  block+=$"    reload_time = 0\n"
  block+=$'}\n\n'
done

# --- inject blocks between markers ---
awk -v content="$block" '
  /^# AUTO BACKGROUND$/ { print; print content; inside=1; next }
  inside && /^# AUTO BACKGROUND END$/ { print; inside=0; next }
  inside { next }
  { print }
' "$CONF" > "${CONF}.tmp" && mv "${CONF}.tmp" "$CONF"

# --- PHASE 1: grim (parallel), then wait ------------------------------------
capture_pids=()
for output in "${outputs[@]}"; do
  (
    grim -l 0 -o "$output" "/tmp/${output}-lockscreen.tmp.png"
  ) & capture_pids+=("$!")
done
for pid in "${capture_pids[@]}"; do wait "$pid"; done

# --- PHASE 2 (BACKGROUND): spots in parallel -> atomic swap -> single reload -
(
  set -e
  effect_pids=()
  for output in "${outputs[@]}"; do
    (
      tmp="/tmp/${output}-lockscreen.tmp.png"
      final="/tmp/${output}-lockscreen.png"
      work="/tmp/${output}-lockscreen.work.png"

      # run effect to a work file (silent), then swap atomically
      bash "$HOME/.config/hypr/scripts/utils/spots.sh" -s 15 "$tmp" "$work" > /dev/null 2>&1
      mv -f -- "$work" "$final"
      rm -f -- "$tmp"
    ) & effect_pids+=("$!")
  done
  for pid in "${effect_pids[@]}"; do wait "$pid"; done

  # single reload after all images are ready
  pkill -USR2 hyprlock 2>/dev/null || true
) &

sleep .5

# --- lock now; then clean AUTO section (foreground) --------------------------
loginctl lock-session

# brief cushion so hyprlock reads the injected blocks
sleep 1

# clean the AUTO BACKGROUND section, keep the markers
sed -i '/^# AUTO BACKGROUND$/,/^# AUTO BACKGROUND END$/{//!d}' "$CONF"

exit 0
