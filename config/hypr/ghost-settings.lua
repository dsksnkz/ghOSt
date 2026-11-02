-- The ghOSt look and input. Added only to a configuration that has no ghOSt shortcuts of its own.
hl.config({
    dwindle = { preserve_split = true },
    general = {
        border_size = 0,
        gaps_in = 4,
        gaps_out = 6,
        float_gaps = 6,
        resize_on_border = true,
        extend_border_grab_area = 30,
    },
    decoration = {
        rounding = 12,
        active_opacity = 1,
        inactive_opacity = 0.87,
        blur = { enabled = true, size = 6, passes = 1, new_optimizations = true },
        shadow = { enabled = false },
    },
    input = {
        accel_profile = "flat",
        touchpad = { natural_scroll = true, disable_while_typing = false },
    },
    misc = {
        focus_on_activate = false,
        font_family = "Adwaita Sans",
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
})
hl.window_rule({ match = { class = "kitty" }, fullscreen_state = 0 })
hl.window_rule({ name = "ghost-clipse", match = { class = "^clipse$" }, float = true, size = { 900, 600 }, center = true, fullscreen_state = "0 0", suppress_event = "maximize" })
