-- Converted from animation.conf to Hyprland Lua config style.

hl.config({
    animations = {
        enabled = "yes, please :)",
    },
})

hl.bezier("easeOutQuint", 0.23, 1, 0.32, 1)
hl.bezier("easeInOutCubic", 0.65, 0.05, 0.36, 1)
hl.bezier("linear", 0, 0, 1, 1)
hl.bezier("almostLinear", 0.5, 0.5, 0.75, 1.0)
hl.bezier("quick", 0.15, 0, 0.1, 1)

hl.animation([[global, 1, 10, default]])
hl.animation([[border, 1, 5.39, easeOutQuint]])
hl.animation([[windows, 1, 4.79, easeOutQuint]])
hl.animation([[windowsIn, 1, 4.1, easeOutQuint, popin 87%]])
hl.animation([[windowsOut, 1, 1.49, linear, popin 87%]])
hl.animation([[fadeIn, 1, 1.73, almostLinear]])
hl.animation([[fadeOut, 1, 1.46, almostLinear]])
hl.animation([[fade, 1, 3.03, quick]])
hl.animation([[layers, 1, 3.81, easeOutQuint]])
hl.animation([[layersIn, 1, 4, easeOutQuint, fade]])
hl.animation([[layersOut, 1, 1.5, linear, fade]])
hl.animation([[fadeLayersIn, 1, 1.79, almostLinear]])
hl.animation([[fadeLayersOut, 1, 1.39, almostLinear]])
hl.animation([[workspaces, 1, 1.94, almostLinear, slidevert]])
hl.animation([[workspacesIn, 1, 1.21, almostLinear, slidevert]])
hl.animation([[workspacesOut, 1, 1.94, almostLinear, slidevert]])
