-- Added only to a configuration that has no ghOSt shortcuts of its own.
local home = assert(os.getenv("HOME"), "HOME is required")
local function bind(key, command, options)
    hl.unbind(key)
    hl.bind(key, hl.dsp.exec_cmd(command), options)
end
bind("SUPER + Space", "quickshell ipc -c ghost-bar call bar toggle launcher")
bind("SUPER + I", "quickshell ipc -c ghost-bar call bar settings general")
bind("SUPER + L", home .. "/.local/bin/ghost lock", { locked = true })
bind("XF86PowerOff", home .. "/.local/bin/ghost lock", { locked = true })
