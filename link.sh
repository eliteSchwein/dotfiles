#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
CONFIGS_DIR="$DOTFILES_DIR/configs"
TARGET_CONFIG="$HOME/.config"
RECURSIVE_LINK_DIRS=("xfce4")

echo "🔗 Linking config files from $CONFIGS_DIR into $TARGET_CONFIG..."

mkdir -p "$TARGET_CONFIG"

for config_name in "${RECURSIVE_LINK_DIRS[@]}"; do
    config_dir="$CONFIGS_DIR/$config_name"
    target_dir="$TARGET_CONFIG/$config_name"

    echo "📁 Recursively processing $config_name"

    if [ ! -d "$config_dir" ]; then
        echo "⛔ Directory $config_dir does not exist. Skipping."
        continue
    fi

    if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
        echo "⚠️  Removing existing $target_dir"
        rm -rf "$target_dir"
    fi

    echo "✅ Linking $config_dir → $target_dir"
    ln -s "$config_dir" "$target_dir"
done

for config_dir in "$CONFIGS_DIR"/*; do
  config_name=$(basename "$config_dir")
  target_dir="$TARGET_CONFIG/$config_name"

  echo "📁 Processing $config_name"

  if [[ "$config_name" == "systemd" ]]; then
    # Recursively link only files in systemd
    find "$config_dir" -type f | while read -r src_file; do
      rel_path="${src_file#$CONFIGS_DIR/}"
      target_path="$TARGET_CONFIG/$rel_path"
      target_parent=$(dirname "$target_path")

      mkdir -p "$target_parent"

      if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        echo "⚠️  Removing existing $target_path"
        rm -rf "$target_path"
      fi

      echo "✅ Linking $src_file → $target_path"
      ln -s "$src_file" "$target_path"
    done
  else
    # Non-systemd: one level deep, only link files
    mkdir -p "$target_dir"
    for item in "$config_dir"/*; do
      [ -f "$item" ] || continue
      item_name=$(basename "$item")
      target_item="$target_dir/$item_name"

      if [ -e "$target_item" ] || [ -L "$target_item" ]; then
        echo "⚠️  Removing existing $target_item"
        rm -rf "$target_item"
      fi

      echo "✅ Linking $item → $target_item"
      ln -s "$item" "$target_item"
    done
  fi
done

# Symlink .zshrc separately
ZSHRC_SOURCE="$DOTFILES_DIR/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"

echo "🔗 Linking $ZSHRC_SOURCE → $ZSHRC_TARGET"

if [ -e "$ZSHRC_TARGET" ] || [ -L "$ZSHRC_TARGET" ]; then
  echo "⚠️  Removing existing $ZSHRC_TARGET"
  rm -rf "$ZSHRC_TARGET"
fi

ln -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
echo "✅ .zshrc linked."

echo "🎉 Dotfiles install complete!"
