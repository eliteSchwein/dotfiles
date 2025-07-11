#!/bin/bash

THEME_PATH="/usr/share/themes/"

# Hyprland Core
paru -S --noconfirm \
  qt5-wayland qt6-wayland hyprland \
  xdg-desktop-portal-hyprland xdg-desktop-portal-wlr xdg-desktop-portal \
  hypridle hyprlock hyprpaper hyprpicker hyprpolkitagent \
  hyprshot kitty gnome-keyring curl wget cmake meson cpio pkg-config gcc

# Addons
paru -S --noconfirm \
  ydotool emote papirus-icon-theme-git satty \
  gimp clipse-bin \
  power-profiles-daemon \
  seahorse wl-clipboard phinger-cursors zsh \
  brightnessctl playerctl inotify-tools \
  thunar gvfs gvfs-smb gvfs-afc gvfs-mtp

# Utilities
paru -S --noconfirm \
  firefox \
  legcord-git \
  ungoogled-chromium-bin \
  tauon-music-box

# Astal
paru -S --noconfirm \
  aylurs-gtk-shell \
  libastal-meta \
  libastal-gjs

# Social Media stuff
paru -S --noconfirm \
  legcord-git

ags init --gtk 3

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

bash install_fonts.sh

bash link.sh
