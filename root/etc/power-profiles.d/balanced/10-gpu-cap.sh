#!/usr/bin/env bash
set -euo pipefail

# 1. Trigger your existing GPU script
if [[ -x "/etc/power-profiles.d/gpu-power-cap.sh" ]]; then
  /etc/power-profiles.d/gpu-power-cap.sh balanced
fi

# 2. Shift CPU to balanced responsiveness (Intel & AMD)
if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]; then
  echo "balance_performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null
fi

# 3. Enable Turbo Boost (Intel & AMD paths)
[[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]] && echo "0" > /sys/devices/system/cpu/intel_pstate/no_turbo
[[ -f /sys/devices/system/cpu/cpufreq/boost ]] && echo "1" > /sys/devices/system/cpu/cpufreq/boost

echo "[power-profiles] Shifted system to Balanced mode."