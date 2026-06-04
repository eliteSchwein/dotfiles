-- Converted from nvidia.conf to Hyprland Lua config style.

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
hl.env("NVD_BACKEND", "direct")
hl.env("EGL_PLATFORM", "wayland")
-- hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")
hl.env("LD_PRELOAD", "/usr/lib/libnvidia-glvkspirv.so")
