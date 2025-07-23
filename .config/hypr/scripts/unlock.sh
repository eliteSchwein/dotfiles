#!/bin/bash

# Check for FIX_UNLOCK file
if [[ ! -f /tmp/FIX_UNLOCK ]]; then
    exit 0
fi

rm /tmp/FIX_UNLOCK

# Wait for Hyprland a bit
sleep 5

# Reload Hyprland configuration
hyprctl reload

# Reset virtual desktops
hyprctl dispatch vdeskreset

sleep 1

# Reset virtual desktops workspaces
hyprctl dispatch vdesk 99
sleep 0.5
hyprctl dispatch lastdesk

# Restart ags
ags quit
bash -c "ags run $HOME/.config/ags/app" &