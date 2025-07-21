#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Theme colors (used with astal)
THEME_COLORS=(
  "0D47A1"
  "9CCC65"
  "FFB300"
  "F4511E"
  "FFB300"
  "0D47A1"
  "F4511E"
)

# Gradient background colors for active border
BACKGROUND_COLORS=(
  "rgba(0D47A1EE) rgba(0D47A1EE) 45deg"
  "rgba(9CCC65EE) rgba(558B2FEE) 45deg"
  "rgba(FFB300EE) rgba(FF6F00EE) 45deg"
  "rgba(F4511EEE) rgba(BF360CEE) 45deg"
  "rgba(FFB300EE) rgba(FF6F00EE) 45deg"
  "rgba(0D47A1EE) rgba(0D47A1EE) 45deg"
  "rgba(F4511EEE) rgba(BF360CEE) 45deg"
)

# List of wallpapers to rotate
IMAGES=(
  "$WALLPAPER_DIR/blue-nebula-37911-3840x2160.png"
  "$WALLPAPER_DIR/HighResScreenShot_2023-11-16_22-23-34.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-05-03_19-53-37.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-05-24_20-52-31.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-05-31_23-06-14.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-08-07_19-26-10.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-08-18_18-41-35.png"
)

# Function to apply background color, wallpaper, and theme color
set_theme() {
  local index=$1
  local bg_color="${BACKGROUND_COLORS[index]}"
  local theme_color="${THEME_COLORS[index]}"
  local image="${IMAGES[index]}"

  hyprctl hyprpaper unload all
  hyprctl keyword general:col.active_border "$bg_color"
  cp -r "$image" "/tmp/wallpaper.png"
  hyprctl hyprpaper preload "/tmp/wallpaper.png"
  hyprctl hyprpaper wallpaper ",/tmp/wallpaper.png"
  astal changeThemeColor "$theme_color" > /dev/null &
}

# Set initial wallpaper and theme
set_theme 0

# Unload temporary start wallpaper if it exists
hyprctl hyprpaper unload "$WALLPAPER_DIR/start.png"

# Main loop for rotating wallpapers and themes
while true; do
  for i in "${!BACKGROUND_COLORS[@]}"; do
    # Pause if screen is locked
    while pgrep -x hyprlock > /dev/null; do
      sleep 5
    done

    set_theme "$i"
    sleep 600
  done
done
