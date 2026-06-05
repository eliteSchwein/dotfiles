-- Converted from gestures.conf to Hyprland Lua config style.

hl.gesture({
    fingers = 3,
    direction = "swipe",
    action = "move",
})

hl.gesture({
    fingers = 3,
    direction = "left",
    mods = "SUPER",
    scale = 1.5,
    action = "float",
})

hl.gesture({
    fingers = 3,
    direction = "up",
    mods = "SUPER",
    scale = 1.5,
    action = "fullscreen",
})
