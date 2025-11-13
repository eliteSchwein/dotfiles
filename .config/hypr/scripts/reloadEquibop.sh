#!/bin/bash

# Tool used to simulate Ctrl+R (choose one)
KEY_TOOL="wtype"  # or "ydotool"

# Get the current workspace ID
current_ws=$(hyprctl activeworkspace -j | jq -r '.id')

# Get the currently focused window address
focused_window=$(hyprctl activewindow -j)
focused_address=$(echo "$focused_window" | jq -r '.address')

# Get Equibop window info by class
equibop_info=$(hyprctl clients -j | jq -c '.[] | select(.class == "equibop")')

if [[ -z "$equibop_info" ]]; then
  echo "Equibop window not found"
  exit 1
fi

equibop_address=$(echo "$equibop_info" | jq -r '.address')
equibop_workspace=$(echo "$equibop_info" | jq -r '.workspace.id')

# Move Equibop to current workspace silently
hyprctl dispatch movetoworkspacesilent "$current_ws,address:$equibop_address"
sleep 0.2

# Focus Equibop
hyprctl dispatch focuswindow "address:$equibop_address"
sleep 0.15

# Send Ctrl+R
if [[ "$KEY_TOOL" == "wtype" ]]; then
  wtype -M ctrl -k r -m ctrl
elif [[ "$KEY_TOOL" == "ydotool" ]]; then
  sudo ydotool key 29:1 19:1 19:0 29:0
fi

# Wait a bit for the command to process
sleep 0.15

# Refocus the previously active window
hyprctl dispatch focuswindow "address:$focused_address"
sleep 0.1

# Move Equibop back to its original workspace
hyprctl dispatch movetoworkspacesilent "$equibop_workspace,address:$equibop_address"
