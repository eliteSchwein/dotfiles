#!/usr/bin/env bash
set -euo pipefail

URL="http://www.fmwconcepts.com/imagemagick/downloadcounter.php?scriptname=spots&dirname=spots"
DEST_DIR="$HOME/.config/hypr/scripts/utils"
DEST="$DEST_DIR/spots.sh"

mkdir -p "$DEST_DIR"

# Download to a temp file first (atomic replace)
tmp="$(mktemp "${DEST_DIR}/spots.sh.XXXXXX")"

# Use curl if available, otherwise wget
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$tmp"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "$URL"
else
  echo "Error: need curl or wget installed." >&2
  exit 1
fi

# Replace 'convert' commands with 'magick' (word-boundary safe)
# (GNU sed: \< and \> match word boundaries)
sed -i 's/\<convert\>/magick/g' "$tmp"

# Make executable and move into place atomically
chmod +x "$tmp"
mv -f "$tmp" "$DEST"

echo "Installed spots.sh -> $DEST (converted 'convert' -> 'magick')"
