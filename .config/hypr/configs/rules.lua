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

hl.window_rule({
    name = "fusion360-main",
    match = {
        class = "^steam_proton$",
        title = ".*Autodesk Fusion.*",
    },

    no_blur = true,
    no_shadow = true,
    opaque = true,
})

-- Fusion's radial "Marking Menu" is a transparent overlay covering the whole monitor.
-- Fusion main window: it maps as "Autodesk Fusion " and requests fullscreen right after; keep it floating.
hl.window_rule({
    name = "fusion360-startup-float",
    match = {
        class = "^steam_proton$",
        initial_title = "^Autodesk Fusion ?$",
    },

    suppress_event = "fullscreen maximize",
    float = true,
    size = "monitor_w*0.8 monitor_h*0.8",
    center = true,
})

-- Must cover the monitor exactly (Fusion draws the menu at absolute coords), but must NOT be
-- fullscreen: Hyprland stops rendering the windows behind a fullscreen window.
hl.window_rule({
    name = "fusion360-marking-menu",
    match = {
        title = "^Marking Menu$",
    },

    -- fake fullscreen: Hyprland keeps it a normal floating window, the client is told it's fullscreen
    fullscreen_state = "0 2",
    suppress_event = "maximize",
    float = true,
    move = "0 0",
    size = "monitor_w monitor_h",
    no_blur = true,
    no_shadow = true,
    no_dim = true,
    no_anim = true,
    border_size = 0,
    rounding = 0,
})

-- The Fusion window the menu belongs to: same process, most recently focused, not the menu itself.
local function fusion_main_window(menu)
    local best = nil
    for _, c in ipairs(hl.get_windows() or {}) do
        if c.pid == menu.pid and c.address ~= menu.address and c.mapped and c.title ~= "Marking Menu" then
            if not best or (c.focus_history_id or 999) < (best.focus_history_id or 999) then
                best = c
            end
        end
    end
    return best
end

-- The static move/size of the rule above don't stick on the real window (Wine resizes it after map),
-- so place it from here. Under winewayland Wine doesn't know where the compositor put its windows:
-- it assumes the Fusion window sits at the monitor origin and draws the menu at the cursor position
-- relative to that. So the overlay has to start at the Fusion window's real top-left corner, not at
-- the monitor's, otherwise the menu is off by the window's offset on screen.
local function fit_fusion_marking_menu(w)
    if not w or w.class ~= "steam_proton" or w.title ~= "Marking Menu" then return end

    local m = w.monitor
    if not m or not w.floating then return end

    local target = m.position
    local main = fusion_main_window(w)
    if main then target = main.at end

    local at, size = w.at, w.size
    if at.x == target.x and at.y == target.y and size.x == m.width and size.y == m.height then return end

    local sel = "address:" .. w.address
    hl.dispatch(hl.dsp.window.resize({ x = m.width, y = m.height, window = sel }))
    hl.dispatch(hl.dsp.window.move({ x = target.x, y = target.y - 20, window = sel }))
end

-- Wine may resize the window again right after it maps, so re-check twice shortly after.
local function fit_fusion_marking_menu_retry(w)
    if not w or w.class ~= "steam_proton" or w.title ~= "Marking Menu" then return end

    fit_fusion_marking_menu(w)

    local sel = "address:" .. w.address
    for _, delay in ipairs({ 60, 200 }) do
        hl.timer(function()
            fit_fusion_marking_menu(hl.get_window(sel))
        end, { timeout = delay, type = "oneshot" })
    end
end

hl.on("window.title", fit_fusion_marking_menu_retry)
hl.on("window.open", fit_fusion_marking_menu_retry)
