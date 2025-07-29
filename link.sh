#!/bin/bash

stow -v --adopt -R .

cp $HOME/.local/share/TauonMusicBox/theme/Schw31n.ttheme $HOME/.local/share/TauonMusicBox/theme/Schw31nFIX.ttheme

fc-cache

echo "🎉 Dotfiles install complete!"
