local function has_amd_gpu()
    local handle = io.popen([[
        if command -v lspci >/dev/null 2>&1; then
            lspci -nn | grep -E 'VGA|3D|Display' | grep -Ei 'AMD|ATI' >/dev/null && echo 1 && exit
        fi

        lsmod 2>/dev/null | grep -q '^amdgpu\b' && echo 1 && exit

        echo 0
    ]])

    if not handle then
        return false
    end

    local result = handle:read("*a")
    handle:close()

    return result:match("1") ~= nil
end

local function configure_amd_gpu()
    hl.env("AMD_USERQ", "1")
    -- hl.env("radv_zero_vram", "1")
end

if has_amd_gpu() then
    configure_amd_gpu()
end
