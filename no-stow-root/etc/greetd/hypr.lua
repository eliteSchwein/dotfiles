hl.env("DMS_RUN_GREETER", "1")

hl.config({
    misc = {
        disable_hyprland_logo = true
    }
})

require("$HOME/.config/hypr/dms/outputs.lua")
