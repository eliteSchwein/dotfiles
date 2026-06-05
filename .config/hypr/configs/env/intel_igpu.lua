-- Converted from intel_igpu.conf to Hyprland Lua config style.

local function has_intel_gpu()
    local handle = io.popen([[
        if command -v lspci >/dev/null 2>&1; then
            lspci -nn | grep -E 'VGA|3D|Display' | grep -qi intel && echo 1 && exit
        fi

        lsmod 2>/dev/null | grep -q '^i915' && echo 1 && exit
        lsmod 2>/dev/null | grep -q '^xe' && echo 1 && exit

        echo 0
    ]])

    if not handle then
        return false
    end

    local result = handle:read("*a")
    handle:close()

    return result:match("1") ~= nil
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

if has_intel_gpu() then
    configure_intel_gpu()
end
