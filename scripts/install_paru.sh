#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Paru Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Updating pacman"
sudo pacman -Syu "${PACMAN_FLAGS[@]}"

log_info "Installing build Packages"
sudo pacman -S stow mold pigz lbzip2 lzip tar bzip2 zstd "${PACMAN_FLAGS[@]}"

log_info "Installing rustup"
sudo pacman -S rustup "${PACMAN_FLAGS[@]}"

log_info "Linking pacman.conf"
PACMAN_CONF_SOURCE="$ROOT_DIR/root/etc/pacman.conf"

if [[ ! -f "$PACMAN_CONF_SOURCE" ]]; then
  log_error "Missing pacman config: $PACMAN_CONF_SOURCE"
  exit 1
fi

sudo rm -f /etc/pacman.conf
sudo ln -s "$PACMAN_CONF_SOURCE" /etc/pacman.conf

rustup default stable
rustup update

log_info "Install Paru Dependencies"
sudo pacman -S base-devel "${PACMAN_FLAGS[@]}"

log_info "Clone Paru"
rm -rf paru
git clone https://aur.archlinux.org/paru.git
cd paru

log_info "Install Paru"
makepkg -si --noconfirm

log_info "Cleanup Paru clone folder"
cd ..
rm -rf paru

log_ok "Paru Install: done"
