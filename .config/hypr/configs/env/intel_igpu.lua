-- Converted from intel_igpu.conf to Hyprland Lua config style.

hl.env("LIBVA_DRIVER_NAME", "iHD")
-- hl.env("GBM_BACKEND", "mesa")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "intel")
hl.env("__NV_PRIME_RENDER_OFFLOAD", "0")

-- hl.env("DXVK_FILTER_DEVICE_NAME", "Intel,")
-- hl.env("VKD3D_FILTER_DEVICE_NAME", "Intel")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
-- hl.env("__VK_LAYER_NV_optimus", "non_NVIDIA_only")
hl.env("WLR_RENDER_DRM_DEVICE", "/dev/dri/renderD128")
