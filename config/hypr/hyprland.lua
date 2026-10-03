-- ghOSt settings — staged, not installed
-- Backend mappings below are staged; live shortcuts are not replaced.


------------------
---- MONITORS ----
------------------

hl.monitor({
    output = "eDP-1",
    disabled = true
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200", -- Alternative: Replace "preferred" with your resolution, e.g., "1920x1080@200"
    scale = 1
})





-- [default stuff]

local mod = "SUPER"
local terminal = "kitty"
local files = "nautilus"
local launcher = "quickshell ipc -c ghost-bar call bar toggle launcher"






-- [AUTOSTART]

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -d -n -c ghost-bar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd("systemd-run --user --unit=ghost-hypridle --collect hypridle")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)




-- [SETTINGS]

hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_SIZE", "20")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("NIXOS_OZONE_WL", "1")

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/bin/hyprlock", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 10,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
        col = {
          active_border = "rgb(9a9996)",   -- Active window color
          inactive_border = "rgb(5e5c64)", -- Inactive window color

        },
    },
    decoration = {
        rounding = 18,
        rounding_power = 3.0,
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        fullscreen_opacity = 1.0,
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            vibrancy = 0.22,
            vibrancy_darkness = 0.10,
            special = true,
            popups = true,
            popups_ignorealpha = 0.16,
        },
        shadow = {
            enabled = true,
            range = 24,
            render_power = 3,
            color = "rgba(07101c72)",
            scale = 0.96,
        },
        dim_inactive = true,
        dim_strength = 0.035,
    },
    animations = { enabled = true, workspace_wraparound = true },
    input = {
        kb_layout = "us",
        repeat_rate = 30,
        repeat_delay = 450,
        follow_mouse = 1,
        sensitivity = -0.15,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 1.0,
        },
    },
    gestures = { workspace_swipe_distance = 260, workspace_swipe_cancel_ratio = 0.22 },
    binds = { scroll_event_delay = 60 },
    dwindle = { preserve_split = true, smart_split = false },
    master = { new_status = "master" },
    misc = {
        allow_session_lock_restore = true,
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        focus_on_activate = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    render = { direct_scanout = false },
    xwayland = { force_zero_scaling = true },
})

-- Fixed monochrome styling; no legacy palette runtime is loaded.

hl.curve("ghost_soft", { type = "bezier", points = { { 0.22, 0.72 }, { 0.18, 1.0 } } })
hl.curve("ghost_release", { type = "bezier", points = { { 0.08, 0.82 }, { 0.14, 1.0 } } })
hl.curve("ghost_quick", { type = "bezier", points = { { 0.34, 0.0 }, { 0.72, 0.18 } } })
hl.curve("ghost_linear", { type = "bezier", points = { { 0.0, 0.0 }, { 1.0, 1.0 } } })
hl.curve("ghost_spring", { type = "spring", mass = 1.0, stiffness = 188, dampening = 23 })

hl.animation({ leaf = "windows", enabled = true, speed = 4.8, bezier = "ghost_release", style = "popin 78%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5.2, bezier = "ghost_release", style = "popin 74%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4.2, bezier = "ghost_quick", style = "popin 82%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5.0, spring = "ghost_spring" })
hl.animation({ leaf = "fade", enabled = true, speed = 4.0, bezier = "ghost_soft" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 5.2, bezier = "ghost_release", style = "slide top" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4.5, bezier = "ghost_quick", style = "slide top" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6.0, bezier = "ghost_release", style = "slidefade 14%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 6.0, bezier = "ghost_release", style = "slidefade 14%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5.0, bezier = "ghost_release", style = "slidefade 14%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5.4, spring = "ghost_spring", style = "slidefadevert 18%" })

hl.layer_rule({ name = "notifications-glass", match = { namespace = "^swaync-.*" }, blur = true, ignore_alpha = 0.12 })

hl.window_rule({ name = "wallpaper-float", match = { title = "^wallpaper-picker$" }, float = true, size = "1500 620", center = true })
hl.window_rule({ name = "clipse-float", match = { class = "clipse" }, float = true, size = "640 680", center = true })
hl.window_rule({ name = "picture-in-picture", match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true, keep_aspect_ratio = true })
hl.window_rule({ name = "no-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ name = "xwayland-drag", match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, no_focus = true })

for workspace = 1, 5 do
    hl.workspace_rule({ workspace = workspace, persistent = true })
end

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + W", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("quickshell ipc -c ghost-bar call bar settings wallpaper"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("zeditor"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(files))
hl.bind(mod .. " + S", hl.dsp.exec_cmd("flatpak run app.zen_browser.zen"))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("quickshell ipc -c ghost-bar call bar sidebar"))
hl.bind(mod .. " + I", hl.dsp.exec_cmd("quickshell ipc -c ghost-bar call bar settings general"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("kitty --class clipse -e clipse"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client --toggle-panel"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("python3 ~/.config/quickshell/ghost-bar/capture.py"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("quickshell ipc -c ghost-bar call bar toggle session"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + T", hl.dsp.window.float())
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + C", hl.dsp.workspace.toggle_special("current"))
hl.bind(mod .. " + SHIFT + C", hl.dsp.window.move({ workspace = "special:current" }))

hl.bind(mod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + DOWN", hl.dsp.focus({ direction = "down" }))

for workspace = 1, 9 do
    hl.bind(mod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(mod .. " + mouse_up", hl.dsp.exec_cmd("python3 ~/.config/quickshell/ghost-bar/workspace_scroll.py -1"))
hl.bind(mod .. " + mouse_down", hl.dsp.exec_cmd("python3 ~/.config/quickshell/ghost-bar/workspace_scroll.py 1"))
hl.bind(mod .. " + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e+1" }))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.25 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
