-- ghOSt-only rules exported from the active desktop; no global window policy.
hl.window_rule({ name = "ghost-settings", match = { class = "org.quickshell", title = "ghOSt Settings" }, float = true, size = { 1024, 699 }, center = true, decorate = false, rounding = 0, opacity = "1 override" })
hl.window_rule({ name = "ghost-intro", match = { class = "org.quickshell", title = "ghOSt Intro" }, float = true, size = { 860, 620 }, center = true, decorate = false, rounding = 0, fullscreen_state = "0 0", suppress_event = "maximize fullscreen", opacity = "1 override" })

-- QML owns its motion. Do not add a second compositor animation on top.
hl.layer_rule({ name = "ghost-motion", match = { namespace = "ghost-(bar|panel|calendar|sidebar|rail-reservation)" }, no_anim = true })
hl.layer_rule({ name = "ghost-lock-exit-motion", match = { namespace = "ghost-lock-exit" }, no_anim = true })

-- Only the clipse terminal floats; ordinary Kitty windows are unaffected.
hl.window_rule({ name = "ghost-clipse", match = { class = "^clipse$" }, float = true, size = { 900, 600 }, center = true, fullscreen_state = "0 0", suppress_event = "maximize" })
