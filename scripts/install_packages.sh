#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Packages Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Core Packages"
paru -S \
  pciutils mold pigz lbzip2 plzip tar bzip2 \
  hyprqt6engine hyprland \
  xdg-desktop-portal-hyprland xdg-desktop-portal-wlr \
  xdg-desktop-portal hyprpicker hyprpolkitagent \
  hyprshot kitty gnome-keyring curl wget cmake meson cpio pkg-config gcc wtype "${PACMAN_FLAGS[@]}"

log_info "Install Addon Packages"
paru -S \
  ark dolphin-plugins kio-extras \
  ydotool emote papirus-icon-theme-git satty \
  gimp clipse-bin jq imagemagick \
  power-profiles-daemon \
  seahorse wl-clipboard phinger-cursors \
  brightnessctl playerctl inotify-tools \
  thunar gvfs gvfs-smb gvfs-afc gvfs-mtp wf-recorder udiskie "${PACMAN_FLAGS[@]}"

log_info "Install Utilities Packages"
paru -S \
  firefox \
  thorium-browser-avx2-bin \
  tauon-music-box \
  vlc vlc-plugins-all \
  stow "${PACMAN_FLAGS[@]}"

log_info "Install Social Media Packages"
paru -S \
  bun equibop-bin "${PACMAN_FLAGS[@]}"

log_ok "Packages Install: done"
