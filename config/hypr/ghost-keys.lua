-- The ghOSt shortcuts and session helpers. Added only to a configuration that has no
-- ghOSt shortcuts of its own, where each one replaces whatever held that key.
local home = assert(os.getenv("HOME"), "HOME is required")
local ghost = home .. "/.local/bin/ghost"
local bar = "quickshell ipc -c ghost-bar call bar "

local function bind(key, action, options)
    pcall(hl.unbind, key)
    hl.bind(key, action, options)
end
local function run(key, command, options)
    bind(key, hl.dsp.exec_cmd(command), options)
end

-- Apps
run("SUPER + W", "kitty --start-as=normal")
run("SUPER + S", "firefox")
run("SUPER + E", "[float; size 1200 720; center] nautilus -w")
run("SUPER + A", "zeditor")
run("SUPER + V", "kitty --start-as=normal --class clipse -e clipse")

-- Shell
run("SUPER + Space", bar .. "toggle launcher")
run("SUPER + I", bar .. "settings general")
run("SUPER + R", bar .. "settings about")
run("SUPER + H", bar .. "settings about")
run("SUPER + B", bar .. "settings wallpaper")
run("SUPER + N", bar .. "settings network")
run("SUPER + M", bar .. "reload")
run("SUPER + L", ghost .. " lock", { locked = true })
run("XF86PowerOff", ghost .. " lock", { locked = true })

-- Windows
bind("SUPER + Q", hl.dsp.window.close())
bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + SHIFT + M", hl.dsp.exit())
bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
for key, direction in pairs({ Left = "left", Right = "right", Up = "up", Down = "down" }) do
    bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
    bind("SUPER + CTRL + " .. key, hl.dsp.window.move({ direction = direction:sub(1, 1) }))
end
for key, delta in pairs({ Left = { -50, 0 }, Right = { 50, 0 }, Up = { 0, -50 }, Down = { 0, 50 } }) do
    bind("SUPER + SHIFT + " .. key, hl.dsp.window.resize({ x = delta[1], y = delta[2], relative = true }), { repeating = true })
end

-- Desktops and Magic Workspaces
for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
    bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end
bind("SUPER + F", hl.dsp.workspace.toggle_special("ai"))
bind("SUPER + G", hl.dsp.workspace.toggle_special("music"))
bind("SUPER + SHIFT + F", hl.dsp.window.move({ workspace = "special:ai" }))
bind("SUPER + SHIFT + G", hl.dsp.window.move({ workspace = "special:music" }))

-- Screenshots
run("SUPER + SHIFT + S", "hyprshot -m region", { locked = true })
run("SHIFT + Print", "hyprshot -m region", { locked = true })
run("SUPER + Print", "hyprshot -m output -m active", { locked = true })
run("SUPER + SHIFT + Print", "hyprshot -m output -m active", { locked = true })

-- Media and hardware keys
run("XF86AudioPause", "playerctl play-pause", { locked = true })
run("XF86AudioPlay", "playerctl play-pause", { locked = true })
run("XF86AudioPrev", "playerctl previous", { locked = true })
run("XF86AudioNext", "playerctl next", { locked = true })
run("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true })
run("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
run("XF86AudioLowerVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%-", { repeating = true, locked = true })
run("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+", { repeating = true, locked = true })
run("XF86MonBrightnessDown", "brightnessctl set 5%- && " .. bar .. "osd brightness", { locked = true })
run("XF86MonBrightnessUp", "brightnessctl set 5%+ && " .. bar .. "osd brightness", { locked = true })
hl.config({ binds = { scroll_event_delay = 10 } })

hl.on("hyprland.start", function()
    hl.exec_cmd(ghost .. " wallpaper")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd(ghost .. " intro")
end)
