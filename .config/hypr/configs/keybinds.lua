-- Converted from keybinds.conf to Hyprland Lua config style.

local mainMod = "SUPER"

local terminal = "kitty"
local fileManager = "dolphin"
local menu = "dms ipc call spotlight toggle"
local colorPicker = "hyprpicker -a -n"
local scriptDir = os.getenv("HOME") .. "/.config/hypr/scripts"

-- Change active window size
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })

-- brrr
hl.bind(mainMod .. " + ALT + SHIFT + right", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + SHIFT + left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })

-- Example binds
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
-- hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pin())
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(colorPicker))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("dms ipc call dankdash wallpaper"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch virtual desktops with mainMod + [1-5]
-- virtual-desktops plugin dispatchers are kept through hyprctl because they are plugin-specific.
for i = 1, 5 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.exec_cmd("hyprctl dispatch vdesk " .. i))
end

-- Move active window to a virtual desktop with mainMod + SHIFT + [1-5]
for i = 1, 5 do
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.exec_cmd("hyprctl dispatch movetodesk " .. i))
end

-- Resets V Desktop
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd([[sh -c 'hyprctl reload; sleep 0.5; hyprctl dispatch vdeskreset; killall dms; dms run --daemon']]))

-- Screenshots Combos
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd('bash "' .. scriptDir .. '/screenshot.sh"'))
hl.bind("Print", hl.dsp.exec_cmd('bash "' .. scriptDir .. '/screenshot.sh"'))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Audio controls / function keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 3"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 3"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"), { locked = true })

-- Brightness controls / function keys
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[dms ipc call brightness increment 5 ""]]), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[dms ipc call brightness decrement 5 ""]]), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Power Keys
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))

-- Misc
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("emote"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))
