-- Converted from nvidia.conf to Hyprland Lua config style.

local function has_nvidia_gpu()
    local handle = io.popen([[
        if command -v lspci >/dev/null 2>&1; then
            lspci -nn | grep -E 'VGA|3D|Display' | grep -qi nvidia && echo 1 && exit
        fi

        lsmod 2>/dev/null | grep -q '^nvidia' && echo 1 && exit

        echo 0
    ]])

    if not handle then
        return false
    end

    local result = handle:read("*a")
    handle:close()

    return result:match("1") ~= nil
end

local function configure_nvidia_gpu()
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
    hl.env("NVD_BACKEND", "direct")
    hl.env("EGL_PLATFORM", "wayland")
    -- hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")
    hl.env("LD_PRELOAD", "/usr/lib/libnvidia-glvkspirv.so")
end

if has_nvidia_gpu() then
    configure_nvidia_gpu()
end
