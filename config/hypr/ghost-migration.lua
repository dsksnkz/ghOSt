-- Optional legacy-shell shortcut replacements. Replace matching bindings,
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

for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end
