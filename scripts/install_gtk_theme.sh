#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "GTK Theme Install: starting"

log_info "Copy Theme"
sudo cp -r .config/hypr/gtk-themes/* /usr/share/themes

log_info "Download Cursor Theme"
curl -fsSL https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2 \
  | sudo tar -xjf - -C /usr/share/icons

log_info "Set Theme"
gsettings set org.gnome.desktop.interface gtk-theme 'Flat-Remix-GTK-Blue-Darkest-Solid'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'phinger-cursors-dark'

log_info "Link GTK 3.0 Theme"
mkdir -p "$HOME/.config/gtk-3.0"
ln -sf "dank-colors.css" "$HOME/.config/gtk-3.0/gtk.css"

log_info "Generate GTK 4.0 Theme"
mkdir -p "$HOME/.config/gtk-4.0"
printf '%s\n' '@import url("dank-colors.css");' > "$HOME/.config/gtk-4.0/gtk.css"

write_qtct_conf() {
  local qtver="$1"                    # 5 or 6
  local dir="$HOME/.config/qt${qtver}ct"
  local conf="$dir/qt${qtver}ct.conf"
  local scheme="$HOME/.local/share/color-schemes/DankMatugen.colors"

  log_info "Generate QT${qtver} Theme"
  mkdir -p "$dir"
  cat > "$conf" <<EOF
[Appearance]
color_scheme_path=$scheme
custom_palette=true
icon_theme=Papirus
EOF
}

write_qtct_conf 6
write_qtct_conf 5

log_ok "GTK Theme Install: done"
