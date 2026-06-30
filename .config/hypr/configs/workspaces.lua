hl.workspace_rule({
    workspace = "special:screenshot",
    on_created_empty = "foot",
})

local mainMod = "SUPER"

local vdesk_count = 10
local monitor_config = {}

local function refresh_monitor_config()
    local mons = hl.get_monitors()
    table.sort(mons, function(a, b) return a.x < b.x end)

    monitor_config = {}
    for i, mon in ipairs(mons) do
        table.insert(monitor_config, {
            name = mon.name,
            offset = (i - 1) * vdesk_count
        })
    end
end

local function set_static_rules()
    for i = 0, 4 do
        local mon_name = "DP-" .. (i + 1)
        for j = 1, vdesk_count do
            local ws_id = tostring((i * vdesk_count) + j)
            hl.workspace_rule({ workspace = ws_id, monitor = mon_name })
        end
    end
end

local function cleanup_orphans()
    local max_allowed_ws = #monitor_config * vdesk_count
    if max_allowed_ws == 0 then return end

    for i = max_allowed_ws + 1, 50 do
        local ws_name = tostring(i)
        local windows = hl.get_workspace_windows(ws_name)
        if windows and #windows > 0 then
            local vdesk_id = ((i - 1) % vdesk_count) + 1
            local new_ws = tostring(((#monitor_config - 1) * vdesk_count) + vdesk_id)
            for _, client in ipairs(windows) do
                    hl.dispatch(hl.dsp.window.move({
                        window = "address:" .. client.address,
                        workspace = tostring(new_ws)
                    }))
            end
        end
    end
end

local function handle_monitor_change()
    refresh_monitor_config()
    hl.exec_cmd("sleep 0.2")
    cleanup_orphans()
end

set_static_rules()
refresh_monitor_config()
hl.on("monitor.added", handle_monitor_change)
hl.on("monitor.removed", handle_monitor_change)

local function switch_vdesk(vdesk_id)
    local active_ws = hl.get_active_workspace()
    if not active_ws then return end
    local original_mon = (type(active_ws.monitor) == "table") and active_ws.monitor.name or active_ws.monitor

    for _, mon in ipairs(monitor_config) do
        local ws_id = tostring(mon.offset + vdesk_id)
        hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
        hl.dispatch(hl.dsp.focus({ workspace = ws_id }))
    end
    if original_mon then hl.dispatch(hl.dsp.focus({ monitor = original_mon })) end
end

local function move_to_vdesk(vdesk_id)
    local follow = true
    local active_ws = hl.get_active_workspace()
    if not active_ws then return end

    local ws_num = tonumber(active_ws.id) or tonumber(active_ws.name)
    if not ws_num then return end

    local active_mon = active_ws.monitor
    if type(active_mon) == "table" then active_mon = active_mon.name end

    for _, mon in ipairs(monitor_config) do
        if ws_num > mon.offset and ws_num <= (mon.offset + vdesk_count) then
            local target_ws = tostring(mon.offset + vdesk_id)
            hl.dispatch(hl.dsp.window.move({ workspace = target_ws, follow = follow }))

            if follow then
                for _, other_mon in ipairs(monitor_config) do
                    if other_mon.name ~= active_mon then
                        local other_ws = tostring(other_mon.offset + vdesk_id)
                        hl.dispatch(hl.dsp.focus({ monitor = other_mon.name }))
                        hl.dispatch(hl.dsp.focus({ workspace = other_ws }))
                    end
                end
                hl.dispatch(hl.dsp.focus({ monitor = active_mon }))
            end
            break
        end
    end
end

for i = 1, vdesk_count do
    local key = tostring(i)
    if i == 10 then key = "0" end
    hl.bind(mainMod .. " + " .. key, function() switch_vdesk(i) end)
    hl.bind(mainMod .. " + SHIFT + " .. key, function() move_to_vdesk(i) end)
end