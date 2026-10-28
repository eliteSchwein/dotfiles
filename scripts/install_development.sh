#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Development Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Editor and CLI Tools"
paru -S \
  neovim ripgrep lazygit yamllint unzip \
  git git-lfs "${PACMAN_FLAGS[@]}"

log_info "Install Languages and Toolchains"
paru -S \
  gcc nodejs npm python go rustup "${PACMAN_FLAGS[@]}"

log_info "Install Kubernetes and Database Tools"
paru -S \
  kubectl freelens-bin dbeaver "${PACMAN_FLAGS[@]}"

log_info "Setup Rust Toolchain"
if ! rustup toolchain list | grep -q .; then
  rustup default stable
fi

log_info "Setup Git LFS"
git lfs install

log_ok "Development Install: done"
