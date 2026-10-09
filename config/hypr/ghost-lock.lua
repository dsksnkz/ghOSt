-- Optional: replace the existing matching lock bindings, do not stack both.
local lockCommand = "quickshell --no-duplicate --path ~/.config/quickshell/ghost-bar/lock.qml"
hl.bind("SUPER + L", hl.dsp.exec_cmd(lockCommand), { locked = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(lockCommand), { locked = true })
hl.layer_rule({ name = "ghost-lock-exit-motion", match = { namespace = "ghost-lock-exit" }, no_anim = true })
