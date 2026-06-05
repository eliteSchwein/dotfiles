-- Converted from layout.conf to Hyprland Lua config style.

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,

        border_size = 2,

        col = {
            active_border = {
                colors = {
                    "rgba(0D47A1EE)",
                    "rgba(0D47A1EE)",
                },
                angle = 45,
            },

            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = true,
        allow_tearing = true,

        layout = "dwindle",
    },

    master = {
        new_status = "master",
    },

    dwindle = {
        preserve_split = true,
    },
})
