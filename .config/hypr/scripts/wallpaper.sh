#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Path to store last used index
INDEX_FILE="/tmp/WALLPAPER_INDEX"

# Theme colors (used with astal)
THEME_COLORS=(
  "3b83f5"
  "9CCC65"
  "FFB300"
  "F4511E"
  "FFB300"
  "3b83f5"
  "F4511E"
  "bd4aed"
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
  "rgba(7B1FA2EE) rgba(6A1B9AEE) 45deg"
)

# List of wallpapers to rotate
IMAGES=(
  "$WALLPAPER_DIR/BlueNebula.png"
  "$WALLPAPER_DIR/HighResScreenShot_2023-11-16_22-23-34.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-05-03_19-53-37.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-05-24_20-52-31.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-05-31_23-06-14.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-08-07_19-26-10.png"
  "$WALLPAPER_DIR/HighResScreenShot_2024-08-18_18-41-35.png"
  "$WALLPAPER_DIR/PurpleNebulaStation.png"
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

  sed -i -E "s/(--accent-[0-9]+: )#[0-9A-Fa-f]+;/\1#$theme_color;/g" "$HOME/.config/legcord/quickCss.css"
  sed -i -E "s/(--accent-new: )#[0-9A-Fa-f]+;/\1#$theme_color;/g" "$HOME/.config/legcord/quickCss.css"

  sed -i -E "s/(--accent-[0-9]+: )#[0-9A-Fa-f]+;/\1#$theme_color;/g" "$HOME/.config/equibop/settings/quickCss.css"
  sed -i -E "s/(--accent-new: )#[0-9A-Fa-f]+;/\1#$theme_color;/g" "$HOME/.config/equibop/settings/quickCss.css"

  bash $HOME/.config/hypr/scripts/reloadEquibop.sh
}


# Load last index if it exists
last_index=-1
if [[ -f "$INDEX_FILE" ]]; then
  last_index=$(<"$INDEX_FILE")
fi

# Generate a new random index that's different
new_index=$((RANDOM % ${#IMAGES[@]}))
while [[ "$new_index" -eq "$last_index" ]]; do
  new_index=$((RANDOM % ${#IMAGES[@]}))
done

# Save the new index
echo "$new_index" > "$INDEX_FILE"

# Apply the new theme
set_theme "$new_index"

# Optionally unload the initial startup wallpaper
hyprctl hyprpaper unload "$WALLPAPER_DIR/BlueNebula.png"