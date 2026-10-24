-- Optional ghOSt shortcut replacements. Replace matching bindings,
-- never load these alongside duplicate combinations. No session action tests.
local mod = _G.mainMod or "SUPER"
local bar = "quickshell ipc -c ghost-bar call bar "

hl.bind(mod .. " + M", hl.dsp.exec_cmd(bar .. "reload"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd(bar .. "toggle launcher"))
hl.bind(mod .. " + R", hl.dsp.exec_cmd(bar .. "settings about"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(bar .. "settings wallpaper"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd(bar .. "settings network"))
-- The old guide page has no exact ghOSt equivalent.
hl.bind(mod .. " + H", hl.dsp.exec_cmd(bar .. "settings about"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("zeditor"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("kitty --start-as=normal --class clipse -e clipse"))

for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scroll = "python3 " .. string.format("%q", config .. "/quickshell/ghost-bar/workspace_scroll.py")
hl.bind(mod .. " + mouse_up", hl.dsp.exec_cmd(scroll .. " -1"))
hl.bind(mod .. " + mouse_down", hl.dsp.exec_cmd(scroll .. " 1"))
hl.config({ binds = { scroll_event_delay = 10 } })
