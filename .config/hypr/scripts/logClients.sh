#!/usr/bin/env bash
# Poll Hyprland clients and append every newly seen one to a file (JSON Lines).
# Clients are never removed; a client is only written the first time its address shows up.
#
# Usage: logClients.sh [duration_s=30] [interval_s=0.25] [outfile=/tmp/hypr-clients.jsonl]
set -euo pipefail

DURATION="${1:-30}"
INTERVAL="${2:-0.25}"
OUT="${3:-/tmp/hypr-clients.jsonl}"

declare -A seen=()
touch "$OUT"

# Re-runs keep appending without writing duplicates of clients already in the file
while IFS= read -r addr; do
  [[ -n "$addr" ]] && seen["$addr"]=1
done < <(jq -r '.address // empty' "$OUT" 2>/dev/null || true)

end=$(( ${EPOCHREALTIME/./} + DURATION * 1000000 ))
new_total=0

while (( ${EPOCHREALTIME/./} < end )); do
  now="$(date -Is)"
  while IFS=' ' read -r addr json; do
    [[ -z "$addr" || -n "${seen[$addr]:-}" ]] && continue
    seen["$addr"]=1
    printf '%s\n' "$json" >> "$OUT"
    new_total=$((new_total + 1))
    echo "$now new: $(jq -r '"\(.class) | \(.title)"' <<<"$json")"
  done < <(hyprctl clients -j 2>/dev/null \
    | jq -r --arg t "$now" '.[] | "\(.address) \(. + {firstSeen: $t} | tojson)"' 2>/dev/null || true)
  sleep "$INTERVAL"
done

echo "Done: $new_total new client(s), ${#seen[@]} total in $OUT"
