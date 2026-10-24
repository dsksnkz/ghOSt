-- Add once, only when another ghOSt autostart is not already present.
-- Optional helpers stay opt-in to avoid starting duplicate existing services.
local home = assert(os.getenv("HOME"), "HOME is required")
local options = _G.ghostAutostart or {}

hl.on("hyprland.start", function()
    hl.exec_cmd(string.format("%q", home .. "/.local/bin/ghost-bar"))
    if options.wallpaperDaemon then
        hl.exec_cmd("awww-daemon")
    end
    if options.clipboardListener then
        hl.exec_cmd("clipse -listen")
    end
end)
