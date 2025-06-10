#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
CONFIGS_DIR="$DOTFILES_DIR/configs"
TARGET_CONFIG="$HOME/.config"

echo "🔗 Linking individual config files from $CONFIGS_DIR into $TARGET_CONFIG..."

mkdir -p "$TARGET_CONFIG"

# Loop through each config directory (e.g., nvim, tmux)
for config_dir in "$CONFIGS_DIR"/*; do
  config_name=$(basename "$config_dir")
  target_dir="$TARGET_CONFIG/$config_name"

  echo "📁 Preparing $target_dir"
  mkdir -p "$target_dir"

  # Loop through the contents of each config subdirectory
  for item in "$config_dir"/*; do
    item_name=$(basename "$item")
    target_item="$target_dir/$item_name"

    # Remove if an old symlink or file exists
    if [ -L "$target_item" ] || [ -f "$target_item" ] || [ -d "$target_item" ]; then
      echo "⚠️  Removing existing $target_item"
      rm -rf "$target_item"
    fi

    echo "✅ Linking $item → $target_item"
    ln -s "$item" "$target_item"
  done
done

# Symlink .zshrc from dotfiles
ZSHRC_SOURCE="$DOTFILES_DIR/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"

echo "🔗 Linking $ZSHRC_SOURCE → $ZSHRC_TARGET"

if [ -L "$ZSHRC_TARGET" ] || [ -e "$ZSHRC_TARGET" ]; then
  echo "⚠️  Removing existing $ZSHRC_TARGET"
  rm -rf "$ZSHRC_TARGET"
fi

ln -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
echo "✅ .zshrc linked."

echo "🎉 Dotfiles install complete!"
