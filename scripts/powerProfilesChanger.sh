#! /bin/bash

BAT=$(echo /sys/class/power_supply/BAT*)
BAT_STATUS="$BAT/status"
BAT_CAP="$BAT/capacity"
LOW_BAT_PERCENT=20
HIGH_BAT_PERCENT=90

AC_PROFILE="performance"
BAT_PROFILE="balanced"
LOW_BAT_PROFILE="power-saver"

# wait a while if needed
[[ -z $STARTUP_WAIT ]] || sleep "$STARTUP_WAIT"

# start the monitor loop
prev=0

while true; do
	# read the current state
	status=$(cat "$BAT_STATUS")
	capacity=$(cat "$BAT_CAP")

	if [[ "$status" == "Discharging" ]]; then
		if [[ $capacity -gt $HIGH_BAT_PERCENT ]]; then
			profile=$AC_PROFILE
		elif [[ $capacity -gt $LOW_BAT_PERCENT ]]; then
			profile=$BAT_PROFILE
		else
			profile=$LOW_BAT_PROFILE
		fi
	else
		profile=$AC_PROFILE
	fi

	# set the new profile
	if [[ $prev != "$profile" ]]; then
		powerprofilesctl set $profile
	fi

	prev=$profile

	# wait for the next power change event
	inotifywait -qq "$BAT_STATUS" "$BAT_CAP"
done
