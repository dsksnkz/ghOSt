-- ghOSt motion: fast start, clean stop, no overshoot.
-- Loaded last so it replaces earlier animation settings. Remove the dofile line to undo.
hl.curve("ghost_direct", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "ghost_direct", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.8, bezier = "ghost_direct", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.5, bezier = "ghost_direct" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.8, bezier = "ghost_direct", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.8, bezier = "ghost_direct", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "ghost_direct", style = "fade" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "ghost_direct" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.6, bezier = "ghost_direct", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2.0, bezier = "ghost_direct", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.8, bezier = "ghost_direct", style = "fade" })
