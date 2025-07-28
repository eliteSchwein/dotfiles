#!/bin/bash

stow --adopt -R .

cp $HOME/.local/share/TauonMusicBox/theme/Schw31n.ttheme $HOME/.local/share/TauonMusicBox/theme/Schw31nFIX.ttheme
echo "🎉 Dotfiles install complete!"
