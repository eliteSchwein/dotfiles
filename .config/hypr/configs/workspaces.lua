hl.workspace_rule({
    workspace = "special:screenshot",
    on_created_empty = "foot",
})

local mainMod = "SUPER"

local vdesk_count = 5
local offset_step = 10

local function get_monitor_config()
    local handle = io.popen([[hyprctl monitors -j | grep -o '"name":"[^"]*"' | cut -d'"' -f4]])
    local monitors = {}

    if handle == nil then
        return monitors
    end

    local index = 0

    for name in handle:lines() do
        table.insert(monitors, {
            name = name,
            offset = index * offset_step,
        })

        index = index + 1
    end

    handle:close()

    return monitors
end

local monitor_config = get_monitor_config()

for _, mon in ipairs(monitor_config) do
    for i = 1, vdesk_count do
        hl.workspace_rule({
            workspace = tostring(mon.offset + i),
            monitor = mon.name,
        })
    end
end

local function switch_vdesk(vdesk_id)
    local active_ws = hl.get_active_workspace()
    local original_mon = active_ws and active_ws.monitor or nil

    if type(original_mon) == "table" then
        original_mon = original_mon.name
    end

    for _, mon in ipairs(monitor_config) do
        local target_ws = tostring(mon.offset + vdesk_id)

        hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
        hl.dispatch(hl.dsp.focus({ workspace = target_ws }))
    end

    if original_mon then
        hl.dispatch(hl.dsp.focus({ monitor = original_mon }))
    end
end

local function move_to_vdesk(vdesk_id)
    local active_ws = hl.get_active_workspace()

    if active_ws == nil then
        return
    end

    local ws_num = tonumber(active_ws.id) or tonumber(active_ws.name)

    if ws_num == nil then
        return
    end

    local active_mon = active_ws.monitor

    if type(active_mon) == "table" then
        active_mon = active_mon.name
    end

    for _, mon in ipairs(monitor_config) do
        local min_ws = mon.offset + 1
        local max_ws = mon.offset + vdesk_count

        if ws_num >= min_ws and ws_num <= max_ws then
            local target_ws = tostring(mon.offset + vdesk_id)

            hl.dispatch(hl.dsp.window.move({
                workspace = target_ws,
                follow = true,
            }))

            for _, other_mon in ipairs(monitor_config) do
                if other_mon.name ~= active_mon then
                    local other_ws = tostring(other_mon.offset + vdesk_id)

                    hl.dispatch(hl.dsp.focus({ monitor = other_mon.name }))
                    hl.dispatch(hl.dsp.focus({ workspace = other_ws }))
                end
            end

            if active_mon then
                hl.dispatch(hl.dsp.focus({ monitor = active_mon }))
            end

            break
        end
    end
end

-- Switch virtual desktops with mainMod + [1-5]
for i = 1, vdesk_count do
    hl.bind(mainMod .. " + " .. i, function()
        switch_vdesk(i)
    end)
end

-- Move active window to a virtual desktop with mainMod + SHIFT + [1-5]
for i = 1, vdesk_count do
    hl.bind(mainMod .. " + SHIFT + " .. i, function()
        move_to_vdesk(i)
    end)
end
