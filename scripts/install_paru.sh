#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Paru Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Updating pacman"
sudo pacman -Syu "${PACMAN_FLAGS[@]}"

log_info "Installing build Packages"
sudo pacman -S mold pigz lbzip2 lzip tar bzip2 zstd "${PACMAN_FLAGS[@]}"

log_info "Installing rustup"
sudo pacman -S rustup "${PACMAN_FLAGS[@]}"

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
