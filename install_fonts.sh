#!/bin/bash

set -e

SOURCE_DIR="$HOME/dotfiles/fonts"
TARGET_BASE="/usr/share/fonts/TTF"

echo "📁 Source directory: $SOURCE_DIR"
echo "📂 Installing to: $TARGET_BASE"

# Verify source exists
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "❌ Source directory does not exist: $SOURCE_DIR"
  exit 1
fi

# Recursively copy all .ttf files, preserving subfolder structure
while IFS= read -r -d '' font_file; do
  # Get relative path from source
  relative_path="${font_file#$SOURCE_DIR/}"
  # Destination path
  target_path="$TARGET_BASE"

  echo "🛠️  Installing $relative_path → $target_path"
  sudo mkdir -p "$target_path"
  sudo cp "$font_file" "$target_path/"
done < <(find "$SOURCE_DIR" -type f -iname "*.ttf" -print0)

# Rebuild font cache
echo "🔄 Rebuilding font cache..."
sudo fc-cache -fv

echo "✅ All fonts installed successfully from $SOURCE_DIR"
