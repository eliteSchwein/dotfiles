#!/bin/bash

hyprctl dispatch dpms on

touch /tmp/FIX_UNLOCK

# Wait for Hyprland a bit
sleep 2

killall hyprlock
pidof hyprlock || hyprlock &

bash $HOME/.config/hypr/scripts/unlock.sh