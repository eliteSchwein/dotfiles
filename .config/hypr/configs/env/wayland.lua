-- Converted from wayland.conf to Hyprland Lua config style.

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("GDK_BACKEND", "wayland,x11,*")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_QPA_PLATFORMTHEME_QT6", "gtk3")
hl.env("OZONE_PLATFORM", "wayland")

hl.env("GTK_THEME", "Flat-Remix-GTK-Blue-Darkest-Solid")

hl.env("TERMINAL", "kitty -1")

hl.config({
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },
})
