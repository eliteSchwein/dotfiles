#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
CONFIGS_DIR="$DOTFILES_DIR/configs"
TARGET_CONFIG="$HOME/.config"

echo "🔗 Linking configs from $CONFIGS_DIR to $TARGET_CONFIG..."

# Ensure .config exists
mkdir -p "$TARGET_CONFIG"

# Link each config subdirectory
for item in "$CONFIGS_DIR"/*; do
  name=$(basename "$item")
  target="$TARGET_CONFIG/$name"

  if [ -L "$target" ] || [ -e "$target" ]; then
    echo "⚠️  Removing existing $target"
    rm -rf "$target"
  fi

  echo "✅ Linking $item → $target"
  ln -s "$item" "$target"
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

echo "🎉 All done!"
