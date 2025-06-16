#!/bin/bash

# Set the luminance threshold
THRESHOLD=75

# Path to the sensor file
SENSOR_PATH="/sys/bus/iio/devices/iio:device0/in_illuminance_raw"

# Check if sensor file exists
if [[ ! -f "$SENSOR_PATH" ]]; then
  echo "Sensor file not found: $SENSOR_PATH"
  exit 1
fi

# Initial state
last_state=""

# Infinite loop
while true; do
  RAW_VALUE=$(cat "$SENSOR_PATH")

  if [[ "$RAW_VALUE" =~ ^[0-9]+$ ]]; then
    # Determine current light state
    if (( RAW_VALUE < THRESHOLD )); then
      current_state="low"
    else
      current_state="high"
    fi

    # Only act on state change
    if [[ "$current_state" != "$last_state" ]]; then
      if [[ "$current_state" == "low" ]]; then
        brightnessctl -sd chromeos::kbd_backlight set 100
      else
        brightnessctl -sd chromeos::kbd_backlight set 0
      fi
      last_state="$current_state"
    fi
  else
    echo "Invalid luminance value: $RAW_VALUE"
  fi

  sleep 0.1
done
