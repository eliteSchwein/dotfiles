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

local function has_intel_arc(pci)
    return pci:match("arc")
        or pci:match("dg2")
        or pci:match("alchemist")
        or pci:match("battlemage")
        or pci:match("bmg")
end

local pci = get_lspci()

local has_nvidia = has_gpu(pci, "nvidia")
local has_amd = has_gpu(pci, "amd") or has_gpu(pci, "ati")
local has_intel = has_gpu(pci, "intel")
local has_arc = has_intel and has_intel_arc(pci)

-- Preference order:
--   NVIDIA dGPU
--   AMD dGPU
--   Intel Arc
--   Intel iGPU
--
-- Intel iGPU is only used as the global/default GPU when no other
-- dedicated GPU is available.

if has_nvidia then
    -- NVIDIA dedicated GPU
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
    hl.env("NVD_BACKEND", "direct")
    hl.env("EGL_PLATFORM", "wayland")

elseif has_amd then
    -- AMD dedicated GPU
    hl.env("LIBVA_DRIVER_NAME", "radeonsi")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
    hl.env("AMD_USERQ", "1")

elseif has_arc then
    -- Intel Arc dedicated GPU
    hl.env("LIBVA_DRIVER_NAME", "iHD")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
    hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")

elseif has_intel then
    -- Intel-only system / Intel iGPU without another GPU
    hl.env("LIBVA_DRIVER_NAME", "iHD")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
    hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
end