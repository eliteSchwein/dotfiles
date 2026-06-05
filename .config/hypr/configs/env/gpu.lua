local function get_lspci()
    local handle = io.popen("lspci -nn 2>/dev/null")
    if not handle then
        return ""
    end

    local output = handle:read("*a") or ""
    handle:close()

    return output:lower()
end

local function has_gpu(pci, vendor)
    return pci:match("vga.-" .. vendor)
        or pci:match("3d.-" .. vendor)
        or pci:match("display.-" .. vendor)
end

local pci = get_lspci()

local has_nvidia = has_gpu(pci, "nvidia")
local has_amd = has_gpu(pci, "amd") or has_gpu(pci, "ati")
local has_intel = has_gpu(pci, "intel")

if has_nvidia then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
    hl.env("NVD_BACKEND", "direct")
    hl.env("EGL_PLATFORM", "wayland")

    -- Optional / risky:
    -- hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")
    -- hl.env("LD_PRELOAD", "/usr/lib/libnvidia-glvkspirv.so")

elseif has_amd then
    hl.env("AMD_USERQ", "1")

    -- Optional:
    -- hl.env("radv_zero_vram", "1")

elseif has_intel then
    hl.env("LIBVA_DRIVER_NAME", "iHD")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
    hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")

    -- Optional:
    -- hl.env("WLR_RENDER_DRM_DEVICE", "/dev/dri/renderD128")
    -- hl.env("DXVK_FILTER_DEVICE_NAME", "Intel")
    -- hl.env("VKD3D_FILTER_DEVICE_NAME", "Intel")
end