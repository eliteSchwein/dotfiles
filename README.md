# SCHW31N Dotfiles

this is based of [Epik Shell](https://github.com/ezerinz/epik-shell), the images are made ingame or with ai.

# link broken?

run this:
```shell
cd $HOME/.config
cp -r hypr hyprbck
rm -rf rm -rf kitty/kitty.conf legcord/quickCss.css satty/config.toml systemd/user/auto_power_profile.service xfce4 hypr ags agsbck
mkdir hypr
cp hyprbck/hyprland.conf hypr/
rm -rf hyprbck
cd $HOME/dotfiles/
bash link,sh
hyprctl reload
```

after that everything should be fine
