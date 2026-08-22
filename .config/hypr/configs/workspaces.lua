hl.workspace_rule({
    workspace = "special:screenshot",
    on_created_empty = "foot",
})

local mainMod = "SUPER"
local vdesk_count = 10
local monitor_config = {}
local is_switching_vdesk = false

local function get_sorted_monitors()
    local raw_mons = hl.get_monitors()
    local active_mons = {}

    for _, mon in ipairs(raw_mons) do
        local is_disabled = (mon.disabled == true) or (mon.disabled == 1) or (mon.disabled == "true")
        if mon.dpmsStatus == false or mon.dpmsStatus == 0 or mon.dpmsStatus == "false" then
            is_disabled = true
        end

        local mirror_val = mon.mirrorOf or mon.mirror or mon.mirror_of
        local is_mirror = false
        if mirror_val ~= nil and mirror_val ~= false then
            local m_str = tostring(mirror_val):lower():gsub("%s+", "")
            if m_str ~= "" and m_str ~= "none" and m_str ~= "nil" and m_str ~= "0" and m_str ~= "false" then
                is_mirror = true
            end
        end

        if not is_disabled and not is_mirror and mon.name and mon.name ~= "" then
            table.insert(active_mons, mon)
        end
    end

    local valid_mons = {}
    local seen_coords = {}
    for _, mon in ipairs(active_mons) do
        local coord_key = tostring(mon.x or 0) .. "x" .. tostring(mon.y or 0)
        if not seen_coords[coord_key] then
            seen_coords[coord_key] = true
            table.insert(valid_mons, mon)
        end
    end

    table.sort(valid_mons, function(a, b) return (a.x or 0) < (b.x or 0) end)
    return valid_mons
end

local function refresh_monitor_config()
    local mons = get_sorted_monitors()

    monitor_config = {}
    for i, mon in ipairs(mons) do
        table.insert(monitor_config, {
            name = mon.name,
            offset = (i - 1) * vdesk_count
        })
    end
end

local function set_static_rules()
    local mons = get_sorted_monitors()

    for i, mon in ipairs(mons) do
        local mon_idx = i - 1

        for j = 1, vdesk_count do
            local ws_id = tostring((mon_idx * vdesk_count) + j)

            local rule = {
                workspace = ws_id,
                monitor = mon.name
            }

            if j == 1 then
                rule.default = true
            end

            hl.workspace_rule(rule)
        end
    end
end

local function fix_startup_workspaces()
    local raw_mons = hl.get_monitors()

    for _, raw_mon in ipairs(raw_mons) do
        local mon_conf = nil
        for _, c in ipairs(monitor_config) do
            if c.name == raw_mon.name then
                mon_conf = c
                break
            end
        end

        if mon_conf and raw_mon.activeWorkspace then
            local active_ws_id = tonumber(raw_mon.activeWorkspace.id) or tonumber(raw_mon.activeWorkspace.name)

            if active_ws_id then
                local expected_min = mon_conf.offset + 1
                local expected_max = mon_conf.offset + vdesk_count

                if active_ws_id < expected_min or active_ws_id > expected_max then
                    local target_ws = tostring(expected_min)

                    local windows = hl.get_workspace_windows(tostring(active_ws_id))
                    if windows and #windows > 0 then
                        for _, client in ipairs(windows) do
                            hl.dispatch(hl.dsp.window.move({
                                window = "address:" .. client.address,
                                workspace = target_ws
                            }))
                        end
                    end
                end
            end
        end
    end

    for _, mon in ipairs(monitor_config) do
        local base_ws = tostring(mon.offset + 1)
        hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
        hl.dispatch(hl.dsp.focus({ workspace = base_ws, on_current_monitor = true }))
    end

    if monitor_config[1] then
        hl.dispatch(hl.dsp.focus({ monitor = monitor_config[1].name }))
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
    set_static_rules()
    cleanup_orphans()
end

local function switch_vdesk(vdesk_id, original_mon)
    if is_switching_vdesk then return end

    if not original_mon then
        local active_mon = hl.get_active_monitor()
        if not active_mon then return end
        original_mon = active_mon.name
    end

    local cursor = hl.get_cursor_pos()
    if not cursor then return end

    local cursor_x = cursor.x
    local cursor_y = cursor.y

    is_switching_vdesk = true

    for _, mon in ipairs(monitor_config) do
        local ws_id = tostring(mon.offset + vdesk_id)

        hl.dispatch(hl.dsp.focus({
            monitor = mon.name
        }))

        hl.dispatch(hl.dsp.focus({
            workspace = ws_id,
            on_current_monitor = true
        }))
    end

    hl.dispatch(hl.dsp.focus({
        monitor = original_mon
    }))

    hl.dispatch(hl.dsp.cursor.move({
        x = cursor_x,
        y = cursor_y
    }))

    is_switching_vdesk = false
end

local function handle_workspace_active(event_data)
    if is_switching_vdesk then return end

    local ws = event_data or hl.get_active_workspace()
    if not ws then return end

    local ws_num = tonumber(ws.id) or tonumber(ws.name)
    if not ws_num then return end

    local event_mon = ws.monitor
    if type(event_mon) == "table" then
        event_mon = event_mon.name
    end

    if not event_mon then return end

    local vdesk_id = ((ws_num - 1) % vdesk_count) + 1

    switch_vdesk(vdesk_id, event_mon)
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
                        hl.dispatch(hl.dsp.focus({
                            workspace = other_ws,
                            on_current_monitor = true
                        }))
                    end
                end
                hl.dispatch(hl.dsp.focus({ monitor = active_mon }))
            end
            break
        end
    end
end


refresh_monitor_config()
set_static_rules()
fix_startup_workspaces()

hl.on("monitor.added", handle_monitor_change)
hl.on("monitor.removed", handle_monitor_change)
hl.on("config.reloaded", handle_monitor_change)
hl.on("workspace.active", handle_workspace_active)

for i = 1, vdesk_count do
    local key = tostring(i)
    if i == 10 then key = "0" end
    hl.bind(mainMod .. " + " .. key, function() switch_vdesk(i) end)
    hl.bind(mainMod .. " + SHIFT + " .. key, function() move_to_vdesk(i) end)
end