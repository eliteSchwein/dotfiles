-- Converted from animation.conf to Hyprland Lua config style.

hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint", {
    type = "bezier",
    points = { {0.23, 1}, {0.32, 1} },
})

hl.curve("easeInOutCubic", {
    type = "bezier",
    points = { {0.65, 0.05}, {0.36, 1} },
})

hl.curve("linear", {
    type = "bezier",
    points = { {0, 0}, {1, 1} },
})

hl.curve("almostLinear", {
    type = "bezier",
    points = { {0.5, 0.5}, {0.75, 1.0} },
})

hl.curve("quick", {
    type = "bezier",
    points = { {0.15, 0}, {0.1, 1} },
})

hl.animation({ leaf = "global", enabled = true, speed = 10, curve = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, curve = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, curve = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, curve = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, curve = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, curve = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, curve = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, curve = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, curve = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, curve = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, curve = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, curve = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, curve = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, curve = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, curve = "almostLinear", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, curve = "almostLinear", style = "slidevert" })
