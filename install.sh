#!/bin/bash

THEME_PATH="/usr/share/themes/"

# Hyprland Core
paru -S --noconfirm --rebuild=all \
  qt5-wayland qt6-wayland hyprland \
  xdg-desktop-portal-hyprland xdg-desktop-portal-wlr xdg-desktop-portal \
  hypridle hyprlock hyprpaper hyprpicker hyprpolkitagent \
  hyprshot kitty gnome-keyring curl wget cmake meson cpio pkg-config gcc

# Addons
paru -S --noconfirm --rebuild=all \
  ydotool emote papirus-icon-theme-git drawing \
  gwenview gimp clipse-bin \
  power-profiles-daemon \
  seahorse kate dolphin wl-clipboard phinger-cursors zsh \
  brightnessctl

# Utilities
paru -S --noconfirm --rebuild=all \
  firefox \
  legcord-git \
  firefox-beta \
  ungoogled-chromium-bin

# Astal
paru -S --noconfirm --rebuild=all \
  aylurs-gtk-shell-git \
  libastal-4-git \
  libastal-apps-git \
  libastal-auth-git \
  libastal-battery-git \
  libastal-bluetooth-git \
  libastal-cava-git \
  libastal-git \
  libastal-gjs-git \
  libastal-greetd-git \
  libastal-hyprland-git \
  libastal-io-git \
  libastal-meta \
  libastal-mpris-git \
  libastal-network-git \
  libastal-notifd-git \
  libastal-powerprofiles-git \
  libastal-river-git \
  libastal-tray-git \
  libastal-wireplumber-git

ags init

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

bash link.sh