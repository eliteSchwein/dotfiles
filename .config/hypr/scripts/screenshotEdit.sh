#!/bin/bash

screenshot_file="$1"
pid_file="$2"

rm $pid_file 2> /dev/null

satty -f="$screenshot_file" --output-filename="$screenshot_file" &
echo $! > "$pid_file"

wait

# Copy screenshot to clipboard
wl-copy < "$screenshot_file"

# Send success notification
#notify-send --app-name=Hyprshot --icon="screenshooter-symbolic" \
#    "Screenshot edited" "Edited Screenshot saved at ${screenshot_file} and in clipboard"

rm $pid_file 2> /dev/null