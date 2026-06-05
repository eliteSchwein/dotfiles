-- Converted from rules.conf to Hyprland Lua config style.

hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    match = { class = "^emote$" },
    stay_focused = true,
})

-- NOTE: idle_inhibit as a window rule was removed in newer Hyprland.
-- Use hypridle rules/config instead.
-- hl.window_rule({
--     match = { title = ".*" },
--     idle_inhibit = "fullscreen",
-- })

hl.window_rule({
    match = { class = "^jetbrains_\\d+$" },
    no_initial_focus = true,
})

hl.window_rule({
    match = { class = "^vrmonitor$" },
    center = true,
})

hl.window_rule({
    match = { class = "^vrwebhelper$" },
    float = true,
    center = true,
})

hl.window_rule({
    match = { class = "^(firefox|Firefox\\ Beta)$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^jetbrains_\\d+$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^steam$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^vrmonitor$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^steam_app_\\d+$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^edhm-ui-v3$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^heroic$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^thunderbird$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^org.gajim.Gajim$" },
    no_blur = true,
})

hl.window_rule({
    match = { class = "^Vmware$" },
    no_blur = true,
})

hl.window_rule({
    match = { title = "^Steam$" },
    tile = true,
})

hl.layer_rule({
    match = { namespace = "^(dms)$" },
    no_anim = true,
})
