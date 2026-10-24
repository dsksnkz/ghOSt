-- Optional: replace the existing matching lock bindings, do not stack both.
local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local lockCommand = "quickshell --no-duplicate --path " .. string.format("%q", config .. "/quickshell/ghost-bar/lock.qml")
hl.bind("SUPER + L", hl.dsp.exec_cmd(lockCommand), { locked = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(lockCommand), { locked = true })
-- The exit animation rule is in ghost-rules.lua; load it only once.
