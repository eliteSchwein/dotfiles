#!/bin/bash

sudo pacman -S rustup

rustup default stable

sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru