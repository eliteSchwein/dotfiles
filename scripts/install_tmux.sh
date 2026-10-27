#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Tmux Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)
PLUGIN_DIR="$HOME/.config/tmux/plugins"
TMUX_CONF="$ROOT_DIR/.config/tmux/tmux.conf"

if [[ ! -f "$TMUX_CONF" ]]; then
  log_error "Tmux config not found: $TMUX_CONF"
  exit 1
fi

log_info "Install Tmux"
sudo pacman -S tmux "${PACMAN_FLAGS[@]}"

log_info "Install TPM and Tmux Plugins"
# Clone the @plugin list from tmux.conf into TPM's layout (plugins/<repo-name>)
# so TPM treats them as installed without needing a running tmux server.
mkdir -p "$PLUGIN_DIR"
while IFS= read -r spec; do
  repo="${spec%%#*}"
  name="${repo##*/}"
  target="$PLUGIN_DIR/$name"
  branch_args=()
  [[ "$spec" == *"#"* ]] && branch_args=(--branch "${spec##*#}")

  if [[ -d "$target" ]]; then
    log_info "Plugin already installed, skipping: $repo"
  else
    log_info "Clone plugin: $repo"
    git clone --depth=1 "${branch_args[@]}" "https://github.com/$repo" "$target"
  fi
done < <(sed -nE "s/^set -g @plugin '([^']+)'.*$/\1/p" "$TMUX_CONF")

log_ok "Tmux Install: done"
