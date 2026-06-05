-- Merged GPU env config for Hyprland Lua.
-- Fast path: run lspci once, then detect vendors from the cached output.

local function read_command(command)
    local handle = io.popen(command)
    if not handle then
        return ""
    end

    local output = handle:read("*a") or ""
    handle:close()

    return output
end

local function has_command(command)
    return os.execute("command -v " .. command .. " >/dev/null 2>&1") == true
end

local gpu_info = ""

if has_command("lspci") then
    gpu_info = read_command("lspci -nn | grep -Ei 'VGA|3D|Display' 2>/dev/null")
end

local gpu_info_lower = gpu_info:lower()

local has_amd = gpu_info_lower:find("amd", 1, true) ~= nil
    or gpu_info_lower:find("ati", 1, true) ~= nil

local has_intel = gpu_info_lower:find("intel", 1, true) ~= nil

local has_nvidia = gpu_info_lower:find("nvidia", 1, true) ~= nil

local function configure_amd_gpu()
    hl.env("AMD_USERQ", "1")
    -- hl.env("radv_zero_vram", "1")
end

local function configure_intel_gpu()
    hl.env("LIBVA_DRIVER_NAME", "iHD")

    -- Mesa / Intel stack
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
    hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")

    -- Optional: force a specific DRM render device.
    -- Might be wrong on multi-GPU systems, so only enable if needed.
    -- hl.env("WLR_RENDER_DRM_DEVICE", "/dev/dri/renderD128")

    -- Optional game filters
    -- hl.env("DXVK_FILTER_DEVICE_NAME", "Intel")
    -- hl.env("VKD3D_FILTER_DEVICE_NAME", "Intel")
end

local function configure_nvidia_gpu()
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
    hl.env("NVD_BACKEND", "direct")
    hl.env("EGL_PLATFORM", "wayland")

    -- Usually not needed and can slow down or break startup on some systems.
    -- hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")
    -- hl.env("LD_PRELOAD", "/usr/lib/libnvidia-glvkspirv.so")
end

-- Priority matters because Intel/NVIDIA both set LIBVA_DRIVER_NAME and GLX vendor.
-- AMD_USERQ is independent and can safely be enabled alongside another GPU.
if has_amd then
    configure_amd_gpu()
end

if has_nvidia then
    configure_nvidia_gpu()
elseif has_intel then
    configure_intel_gpu()
end
