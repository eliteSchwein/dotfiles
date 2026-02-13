#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Packages Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Core Packages"
paru -S \
  pciutils \
  hyprqt6engine hyprland \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal hyprpicker hyprpolkitagent archlinux-xdg-menu \
  hyprshot kitty gnome-keyring curl wget cmake meson cpio pkg-config gcc wtype "${PACMAN_FLAGS[@]}"

log_info "Install Addon Packages"
paru -S \
  ark dolphin-plugins kio-extras kio-fuse \
  ydotool emote papirus-icon-theme-git satty \
  gimp clipse jq imagemagick \
  power-profiles-daemon hypridle \
  seahorse wl-clipboard phinger-cursors \
  brightnessctl playerctl inotify-tools \
  wf-recorder udiskie "${PACMAN_FLAGS[@]}"

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

log_info "Symlink some dependencies Configurations"
sudo ln -s /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu

log_ok "Packages Install: done"
