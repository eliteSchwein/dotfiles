#!/bin/bash
set -euo pipefail

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Path to store last used index
INDEX_FILE="/tmp/WALLPAPER_INDEX"

# Where to write the decimal accent value
HYPRTK="$HOME/.config/hypr/hyprtoolkit.conf"

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
  "C62828"
  "FBC02D"
  "6D4C41"
  "00897B"
  "E64A19"
  "388E3C"
  "039BE5"
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
  "rgba(C62828EE) rgba(B71C1CEE) 45deg"
  "rgba(FBC02DEE) rgba(F9A825EE) 45deg"
  "rgba(6D4C41EE) rgba(4E342EEE) 45deg"
  "rgba(00897BEE) rgba(00695CEE) 45deg"
  "rgba(E64A19EE) rgba(D84315EE) 45deg"
  "rgba(388E3CEE) rgba(1B5E20EE) 45deg"
  "rgba(039BE5EE) rgba(0277BDEE) 45deg"
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
  "$WALLPAPER_DIR/HighResScreenShot_2025-08-19_19-05-56.png"
  "$WALLPAPER_DIR/PantherStation.png"
  "$WALLPAPER_DIR/RoundStation.png"
  "$WALLPAPER_DIR/LagoonSpaceship.png"
  "$WALLPAPER_DIR/Vulcano.png"
  "$WALLPAPER_DIR/JungleTreeHouses.png"
  "$WALLPAPER_DIR/CloudCities.png"
)

# Convert hex (with/without #) to decimal (supports RRGGBB or AARRGGBB)
hex_to_decimal() {
  local hex="${1#\#}"  # strip leading # if present
  if [[ "$hex" =~ ^([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$ ]]; then
    echo $((16#$hex))
  else
    echo "0"
    return 1
  fi
}

# Function to apply background color, wallpaper, and theme color
set_theme() {
  local index=$1
  local bg_color="${BACKGROUND_COLORS[$index]}"
  local theme_color="${THEME_COLORS[$index]}"
  local image="${IMAGES[$index]}"

  # Hyprpaper: clear then set new wallpaper
  hyprctl hyprpaper unload all > /dev/null
  echo "general:col.active_border=$bg_color" > "$HOME/.config/hypr/theme_custom.conf"
  # hyprctl keyword general:col.active_border "$bg_color" > /dev/null

  hyprctl hyprpaper preload "$image" > /dev/null
  hyprctl hyprpaper wallpaper ",$image" > /dev/null
  cp "$image" "/tmp/wallpaper.png" > /dev/null || true

  # astal color (hex)
  astal changeThemeColor "$theme_color" > /dev/null &

  # CSS accents (hex)
  sed -i -E "s/(--accent-[0-9]+: )#[0-9A-Fa-f]+;/\1#$theme_color;/g" "$HOME/.config/legcord/quickCss.css" || true
  sed -i -E "s/(--accent-new: )#[0-9A-Fa-f]+;/\1#$theme_color;/g"        "$HOME/.config/legcord/quickCss.css" || true

  sed -i -E "s/(--accent-[0-9]+: )#[0-9A-Fa-f]+;/\1#$theme_color;/g" "$HOME/.config/equibop/settings/quickCss.css" || true
  sed -i -E "s/(--accent-new: )#[0-9A-Fa-f]+;/\1#$theme_color;/g"        "$HOME/.config/equibop/settings/quickCss.css" || true

  echo "$theme_color" > /tmp/THEME_COLOR

  # --- NEW: add AA=FF before converting to decimal (AARRGGBB) ---
  local theme_color_a="FF${theme_color#\#}"

  # --- write decimal accent value to hyprtoolkit.conf ---
  mkdir -p "$(dirname "$HYPRTK")"
  local color_deci
  color_deci="$(hex_to_decimal "$theme_color_a")"

  # If an 'accent =' line exists (with any number), replace it; else append one.
  if [[ -f "$HYPRTK" ]] && grep -qE '^[[:space:]]*accent[[:space:]]*=[[:space:]]*[0-9]+([[:space:]]*#.*)?$' "$HYPRTK"; then
    sed -i -E "s/^[[:space:]]*accent[[:space:]]*=[[:space:]]*[0-9]+([[:space:]]*#.*)?$/accent = ${color_deci}/" "$HYPRTK"
  else
    echo "accent = ${color_deci}" >> "$HYPRTK"
  fi

  # Reload anything that depends on it
  bash "$HOME/.config/hypr/scripts/reloadEquibop.sh" > /dev/null || true
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
hyprctl hyprpaper unload "$WALLPAPER_DIR/BlueNebula.png" || true
