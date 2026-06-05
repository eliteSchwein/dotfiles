-- Converted from startexec.conf to Hyprland Lua config style.
-- Autostart commands run once on Hyprland start.
-- Shutdown commands run when Hyprland exits.

hl.on("hyprland.start", function()
    -- Bug Fixes
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME")

    -- Plugins
    hl.exec_cmd("hyprpm reload -n")

    -- Dependencies
    hl.exec_cmd("bash $HOME/.config/hypr/scripts/portal.sh")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd([[bash -c "wl-paste --watch cliphist store"]])
    hl.exec_cmd("hypridle")

    -- Navigation
    -- hl.exec_cmd("dms run --daemon")

    -- Communication Apps
    hl.exec_cmd("sleep 2 && thunderbird")
    -- hl.exec_cmd("sleep 2 && gajim")
    -- hl.exec_cmd("sleep 5 && equibop")
    -- hl.exec_cmd("sleep 5 && legcord")

    -- Apps
    -- hl.exec_cmd("streamdeck -n")
    -- hl.exec_cmd("emote")
    hl.exec_cmd("solaar --window=hide")

    -- Automount
    hl.exec_cmd("udiskie -q -T -N")

    -- Power Button Handling
    hl.exec_cmd([[bash -c 'systemd-inhibit --who="Hyprland config" --why="WM logout keybind" --what=handle-power-key --mode=block sleep infinity & echo $! > /tmp/.hyprland-systemd-inhibit']])

    -- Gaming
    -- hl.exec_cmd("steam-native")
    hl.exec_cmd("heroic")
    hl.exec_cmd("sleep 4 && bash $HOME/.config/hypr/scripts/pddFix.sh")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd([[bash -c 'test -f /tmp/.hyprland-systemd-inhibit && kill -9 "$(cat /tmp/.hyprland-systemd-inhibit)"']])
end)
