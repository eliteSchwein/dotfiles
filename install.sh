#!/bin/bash

THEME_PATH="/usr/share/themes/"

bash install_paru.sh

# System Elements
paru -S --noconfirm \
  mold pigz lbzip2 plzip greetd greetd-tuigreet

# Hyprland Core
paru -S --noconfirm \
  qt5-wayland qt6-wayland qt6ct-kde hyprland \
  xdg-desktop-portal-hyprland xdg-desktop-portal-wlr xdg-desktop-portal \
  hypridle hyprlock hyprpicker hyprpolkitagent \
  hyprshot kitty gnome-keyring curl wget cmake meson cpio pkg-config gcc wtype

# Addons
paru -S --noconfirm \
  ydotool emote papirus-icon-theme-git satty \
  gimp clipse-bin jq imagemagick \
  power-profiles-daemon \
  seahorse wl-clipboard phinger-cursors zsh \
  brightnessctl playerctl inotify-tools \
  thunar gvfs gvfs-smb gvfs-afc gvfs-mtp wf-recorder udiskie

# Utilities
paru -S --noconfirm \
  firefox \
  thorium-browser-avx2-bin \
  tauon-music-box \
  vlc vlc-plugins-all \
  stow power-profiles-hooks-fixed

# Quickshell
paru -S --noconfirm dms-shell-bin \
  cava wl-clipboard cliphist brightnessctl qt6-multimedia accountsservice \
  matugen-bin python-pywalfox

# Social Media stuff
paru -S --noconfirm \
  bun-bin equibop-bin

sudo cp -r ./configs/hypr/gtk-themes/* $THEME_PATH

gsettings set org.gnome.desktop.interface gtk-theme 'Flat-Remix-GTK-Blue-Darkest-Solid'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'phinger-cursors-dark'

hyprpm update
hyprpm add https://github.com/levnikmyskin/hyprland-virtual-desktops
hyprpm enable virtual-desktops
hyprpm reload -n

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

bash install_utils.sh
bash link.sh
bash activate_services.sh