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

-- Autodesk Fusion main window.
hl.window_rule({
    name = "fusion360-main",
    match = {
        class = "^steam_proton$",
        title = ".*Autodesk Fusion.*",
    },
    no_blur = true,
    no_shadow = true,
    -- opaque = true,
})

-- Fusion initially maps as "Autodesk Fusion " and requests fullscreen shortly afterward.
-- Keep the main window floating and prevent its fullscreen/maximize requests.
-- hl.window_rule({
    -- name = "fusion360-startup-float",
    -- match = {
    --     class = "^steam_proton$",
    --     initial_title = "^Autodesk Fusion ?$",
    -- },
    -- suppress_event = "fullscreen maximize",
    -- float = true,
    -- size = "monitor_w*0.8 monitor_h*0.8",
    -- center = true,
-- })

-- Fusion's radial "Marking Menu" is a transparent Wine/Wayland overlay.
-- Use fake fullscreen rather than compositor fullscreen so Fusion stays visible behind it.
-- Actual dimensions and position are corrected below using the parent Fusion window.
hl.window_rule({
    name = "fusion360-marking-menu",
    match = {
        class = "^steam_proton$",
        initial_title = "^Marking Menu$",
    },
    fullscreen_state = "0 2",
    suppress_event = "fullscreen maximize",
    float = true,
    size = "monitor_w*0.6 monitor_h*0.5",
    no_blur = true,
    no_shadow = true,
    no_dim = true,
    no_anim = true,
    border_size = 0,
    rounding = 0,
})

-- Find the matching Fusion window belonging to the same Wine process.
local function fusion_main_window(menu)
    for _, c in ipairs(hl.get_windows() or {}) do
        if c.pid == menu.pid
            and c.address ~= menu.address
            and c.mapped
            and c.title
            and c.title:find("Autodesk Fusion", 1, true)
        then
            return c
        end
    end
    return nil
end

-- Position the radial overlay relative to Fusion instead of sizing it to the
-- whole monitor. Avoid unnecessary geometry updates which can cause redraws.
local function fit_fusion_marking_menu(w)
    if not w
        or w.class ~= "steam_proton"
        or w.title ~= "Marking Menu"
        or not w.floating
    then
        return
    end

    local main = fusion_main_window(w)
    if not main then return end

    -- Keep the original 20px Wine coordinate correction.
    local x = main.at.x
    local y = main.at.y - 20

    local width = main.size.x + 32
    local height = main.size.y + 40
    local sel = "address:" .. w.address

    -- Only dispatch when the geometry is actually different.
    if w.size.x ~= width or w.size.y ~= height then
        hl.dispatch(hl.dsp.window.resize({
            x = width,
            y = height,
            window = sel,
        }))
    end

    if w.at.x ~= x or w.at.y ~= y then
        hl.dispatch(hl.dsp.window.move({
            x = x,
            y = y,
            window = sel,
        }))
    end
end

-- Wine may resize the popup after it maps, so verify twice shortly afterward.
local function fit_fusion_marking_menu_retry(w)
    if not w
        or w.class ~= "steam_proton"
        or w.title ~= "Marking Menu"
    then
        return
    end

    fit_fusion_marking_menu(w)

    local sel = "address:" .. w.address
    for _, delay in ipairs({ 60, 200 }) do
        hl.timer(function()
            local current = hl.get_window(sel)
            if current then
                fit_fusion_marking_menu(current)
            end
        end, {
            timeout = delay,
            type = "oneshot",
        })
    end
end

hl.on("window.title", fit_fusion_marking_menu_retry)
hl.on("window.open", fit_fusion_marking_menu_retry)
