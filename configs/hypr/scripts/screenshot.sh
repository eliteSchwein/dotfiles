#!/bin/bash

file_name="$(date +%Y-%m-%d_%H-%M).png"
screenshot_dir="$HOME/Pictures/Screenshots"
screenshot_file="$screenshot_dir/$file_name"
pid_file="/tmp/screenshot_pid"

# Create the screenshot directory if it doesn't exist
mkdir -p "$screenshot_dir"

# Take the screenshot with hyprshot
if hyprshot -zm region -o "$screenshot_dir" -f "$file_name"; then
    sleep 1

    if [[ -f "$screenshot_file" ]]; then
        rm -f "$pid_file" 2> /dev/null

        # Fix potential 10-bit color issues using ImageMagick
        # NOTE: $fx should be defined or this line may fail
        # Remove -fx if it's not needed or not defined
        #magick "$screenshot_file" \
        #    -depth 8 \
        #    -colorspace sRGB \
        #    -gamma 2.2 \
        #    -sigmoidal-contrast 8x50% \
        #    -auto-level \
        #    -normalize \
        #    "$screenshot_file"

        # Open screenshot editor
        bash "$HOME/.config/hypr/scripts/screenshotEdit.sh" "$screenshot_file" "$pid_file" &

        # Move to special workspace for screenshot editing
        hyprctl dispatch workspace special:screenshot

        # Wait for the pid_file to be created
        while [[ ! -f "$pid_file" ]]; do
            sleep 0.5
        done

        drawing_pid=$(cat "$pid_file")

        # Wait until the drawing app shows up in Hyprland
        while ! hyprctl clients | grep -q "$drawing_pid"; do
            sleep 0.5
        done

        hyprctl dispatch movetoworkspace "special:screenshot, pid:$drawing_pid"
    else
        notify-send --app-name=Hyprshot "Screenshot canceled"
        exit 1
    fi
else
    # Send failure notification
    notify-send --app-name=Hyprshot -u critical "Screenshot failed" "Couldn't open screenshot ${screenshot_file}"
    exit 1
fi
