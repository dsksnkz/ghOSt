-- ghOSt workspace switcher. Global shortcuts reach the running shell without spawning a process.
hl.bind("SUPER + Tab", hl.dsp.global("ghost:switcher"))
hl.bind("SUPER + SHIFT + Tab", hl.dsp.global("ghost:switcher-back"))
-- The shell moves the switcher while it is open and changes desktop otherwise.
hl.unbind("SUPER + mouse_up")
hl.unbind("SUPER + mouse_down")
hl.bind("SUPER + mouse_up", hl.dsp.global("ghost:scroll-up"))
hl.bind("SUPER + mouse_down", hl.dsp.global("ghost:scroll-down"))
-- QML owns its motion.
hl.layer_rule({ name = "ghost-switcher-motion", match = { namespace = "ghost-switcher" }, no_anim = true })
