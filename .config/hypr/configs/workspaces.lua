hl.workspace_rule({
    workspace = "special:screenshot",
    on_created_empty = "foot",
})

local mainMod = "SUPER"

local vdesk_count = 5
local offset_step = 10
local outputs_file = os.getenv("HOME") .. "/.config/hypr/dms/outputs.lua"

local debug_log = "/tmp/hypr-vdesk-debug.log"
local debug_parsed_monitors = "/tmp/hypr-vdesk-parsed-monitors.txt"

local function write_file(path, value)
    local file = io.open(path, "w")
    if not file then return end
    file:write(tostring(value or ""))
    file:close()
end

local function log(msg)
    local file = io.open(debug_log, "a")
    if not file then return end
    file:write(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. tostring(msg) .. "\n")
    file:close()
end

local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        log("read failed: " .. tostring(path))
        return ""
    end

    local content = file:read("*a") or ""
    file:close()
    return content
end

local function parse_outputs()
    local content = read_file(outputs_file)
    local monitors = {}

    for block in content:gmatch("hl%.monitor%s*%b()") do
        local output = block:match('output%s*=%s*"([^"]+)"')
        local mirror = block:match('mirror%s*=%s*"([^"]+)"')
        local pos_x = block:match('position%s*=%s*"(-?%d+)x%-?%d+"')

        if output and not mirror then
            table.insert(monitors, {
                name = output,
                x = tonumber(pos_x) or 0,
                offset = 0,
            })
        end
    end

    table.sort(monitors, function(a, b)
        return a.x < b.x
    end)

    local lines = {}

    for index, mon in ipairs(monitors) do
        mon.offset = (index - 1) * offset_step

        table.insert(
            lines,
            "index=" .. tostring(index)
                .. " name=" .. tostring(mon.name)
                .. " x=" .. tostring(mon.x)
                .. " offset=" .. tostring(mon.offset)
        )
    end

    write_file(debug_parsed_monitors, table.concat(lines, "\n"))

    return monitors
end

local monitor_config = parse_outputs()

for _, mon in ipairs(monitor_config) do
    for i = 1, vdesk_count do
        local ws_id = tostring(mon.offset + i)

        log("workspace_rule workspace=" .. ws_id .. " monitor=" .. mon.name)

        hl.workspace_rule({
            workspace = ws_id,
            monitor = mon.name,
        })
    end
end

local function switch_vdesk(vdesk_id)
    log("switch_vdesk " .. tostring(vdesk_id))

    local active_ws = hl.get_active_workspace()
    if active_ws == nil then
        log("switch aborted: no active workspace")
        return
    end

    local original_mon = active_ws.monitor

    log("original_mon=" .. tostring(original_mon))

    for _, mon in ipairs(monitor_config) do
        local ws_id = tostring(mon.offset + vdesk_id)

        log("switch monitor=" .. mon.name .. " workspace=" .. ws_id)

        hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
        hl.dispatch(hl.dsp.focus({ workspace = ws_id }))
    end

    if original_mon then
        log("restore monitor=" .. tostring(original_mon))
        hl.dispatch(hl.dsp.focus({ monitor = original_mon }))
    end
end

local function move_to_vdesk(vdesk_id)
    log("move_to_vdesk " .. tostring(vdesk_id))

    local follow = true
    local active_ws = hl.get_active_workspace()
    if active_ws == nil then
        log("move aborted: no active workspace")
        return
    end

    local ws_num = tonumber(active_ws.id) or tonumber(active_ws.name)
    if not ws_num then
        log("move aborted: invalid ws")
        return
    end

    local active_mon = active_ws.monitor
    if type(active_mon) == "table" then
        active_mon = active_mon.name
    end

    for _, mon in ipairs(monitor_config) do
        if ws_num > mon.offset and ws_num <= (mon.offset + vdesk_count) then
            local target_ws = tostring(mon.offset + vdesk_id)

            log("move target=" .. target_ws)

            hl.dispatch(hl.dsp.window.move({
                workspace = target_ws,
                follow = follow,
            }))

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

    hl.bind(mainMod .. " + " .. key, function()
        switch_vdesk(i)
    end)

    hl.bind(mainMod .. " + SHIFT + " .. key, function()
        move_to_vdesk(i)
    end)
end