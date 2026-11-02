-- Optional: replace the existing matching lock bindings, do not stack both.
local lockCommand = os.getenv("HOME") .. "/.local/bin/ghost lock"
hl.bind("SUPER + L", hl.dsp.exec_cmd(lockCommand), { locked = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(lockCommand), { locked = true })
