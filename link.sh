#!/bin/bash

stow -v --adopt -R . --ignore='^(root(/|$)|install_utils\.sh$|install\.sh$|link\.sh$)'

sudo stow -v -R -t / root

cp $HOME/.local/share/TauonMusicBox/theme/Schw31n.ttheme $HOME/.local/share/TauonMusicBox/theme/Schw31nFIX.ttheme

fc-cache

echo "🎉 Dotfiles install complete!"
