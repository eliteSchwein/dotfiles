-- Unified GPU environment setup for Hyprland Lua.
-- Merges AMD, Intel and NVIDIA detection into one cached probe.

local gpu_preference = {
    "nvidia",
    "amd",
    "intel",
}

local function sh(command)
    local handle = io.popen(command .. " 2>/dev/null")
    if not handle then
        return ""
    end

    local output = handle:read("*a") or ""
    handle:close()
    return output
end

local function detect_gpus()
    -- One lspci call + one lsmod call instead of one shell pipeline per vendor.
    local pci = sh("command -v lspci >/dev/null 2>&1 && lspci -nn")
    local modules = sh("lsmod")

    local pci_lower = pci:lower()

    return {
        amd = pci_lower:match("vga.*amd") ~= nil
            or pci_lower:match("3d.*amd") ~= nil
            or pci_lower:match("display.*amd") ~= nil
            or pci_lower:match("vga.*ati") ~= nil
            or pci_lower:match("3d.*ati") ~= nil
            or pci_lower:match("display.*ati") ~= nil
            or modules:match("^amdgpu%s") ~= nil
            or modules:match("\namdgpu%s") ~= nil,

        intel = pci_lower:match("vga.*intel") ~= nil
            or pci_lower:match("3d.*intel") ~= nil
            or pci_lower:match("display.*intel") ~= nil
            or modules:match("^i915%s") ~= nil
            or modules:match("\ni915%s") ~= nil
            or modules:match("^xe%s") ~= nil
            or modules:match("\nxe%s") ~= nil,

        nvidia = pci_lower:match("vga.*nvidia") ~= nil
            or pci_lower:match("3d.*nvidia") ~= nil
            or pci_lower:match("display.*nvidia") ~= nil
            or modules:match("^nvidia%s") ~= nil
            or modules:match("\nnvidia%s") ~= nil,
    }
end

local function set_envs(envs)
    for key, value in pairs(envs) do
        hl.env(key, value)
    end
end

local function configure_amd_gpu()
    set_envs({
        AMD_USERQ = "1",
        -- radv_zero_vram = "1",
    })
end

local function configure_intel_gpu()
    set_envs({
        LIBVA_DRIVER_NAME = "iHD",
        __GLX_VENDOR_LIBRARY_NAME = "mesa",
        __EGL_VENDOR_LIBRARY_FILENAMES = "/usr/share/glvnd/egl_vendor.d/50_mesa.json",

        -- Optional: force a specific DRM render device.
        -- Might be wrong on multi-GPU systems, so only enable if needed.
        -- WLR_RENDER_DRM_DEVICE = "/dev/dri/renderD128",

        -- Optional game filters.
        -- DXVK_FILTER_DEVICE_NAME = "Intel",
        -- VKD3D_FILTER_DEVICE_NAME = "Intel",
    })
end

local function configure_nvidia_gpu()
    set_envs({
        LIBVA_DRIVER_NAME = "nvidia",
        GBM_BACKEND = "nvidia-drm",
        __GLX_VENDOR_LIBRARY_NAME = "nvidia",
        __NV_PRIME_RENDER_OFFLOAD = "1",
        NVD_BACKEND = "direct",
        EGL_PLATFORM = "wayland",

        -- Enable only if your setup needs explicit NVIDIA EGL vendor selection.
        -- __EGL_VENDOR_LIBRARY_FILENAMES = "/usr/share/glvnd/egl_vendor.d/10_nvidia.json",

        -- This can break some setups if the file is missing or driver versions differ.
        -- LD_PRELOAD = "/usr/lib/libnvidia-glvkspirv.so",
    })
end

local configure = {
    amd = configure_amd_gpu,
    intel = configure_intel_gpu,
    nvidia = configure_nvidia_gpu,
}

local gpus = detect_gpus()

-- Apply non-conflicting AMD tweaks even when AMD is not the primary GPU.
if gpus.amd then
    configure_amd_gpu()
end

-- Pick one primary graphics stack for conflicting env vars like LIBVA/GLX/GBM.
for _, vendor in ipairs(gpu_preference) do
    if gpus[vendor] and vendor ~= "amd" then
        configure[vendor]()
        break
    end
end

-- If this is an AMD-only machine, the AMD config above is enough.
