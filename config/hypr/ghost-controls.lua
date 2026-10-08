-- Optional controls for Hyprland's Lua configuration API.
-- Replace matching old bindings; do not append duplicate key combinations.
-- No compositor, monitor, wallpaper, autostart or session settings are changed.

hl.bind("SUPER + I", hl.dsp.exec_cmd("quickshell ipc -c ghost-bar call bar settings general"))

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%-"), { repeating = true, locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"), { repeating = true, locked = true })

-- Audio OSD follows real PipeWire changes. Brightness requests a read after success.
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%- && quickshell ipc -c ghost-bar call bar osd brightness"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+ && quickshell ipc -c ghost-bar call bar osd brightness"), { locked = true })
