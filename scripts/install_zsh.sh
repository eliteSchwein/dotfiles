#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "ZSH Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install Zsh"
sudo pacman -S zsh zoxide fzf "${PACMAN_FLAGS[@]}"

log_info "Remove present OhMyZsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  rm -rf "$HOME/.oh-my-zsh"
fi

log_info "Install OhMyZsh"
(
  export RUNZSH=no
  export CHSH=yes
  export KEEP_ZSHRC=yes
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
)

log_info "Install OhMyZsh Plugins"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

log_info "Install Powerlevel10k Theme"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

log_info "Install Powerlevel10k recommended MesloLGS NF fonts"
FONT_DIR="$HOME/.local/share/fonts/MesloLGS-NF"
mkdir -p "$FONT_DIR"
for style in "Regular" "Bold" "Italic" "Bold Italic"; do
  filename="MesloLGS NF $style.ttf"
  log_info "Downloading font: $filename"
  curl -fL --retry 3 --output "$FONT_DIR/$filename" \
    "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/${filename// /%20}"
done
fc-cache -f "$FONT_DIR"

log_ok "ZSH Install: done"
