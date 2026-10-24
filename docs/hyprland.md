# Hyprland integration

These scoped Lua snippets reflect the current ghOSt integration on Hyprland
0.56.2. They are **not** a replacement for your compositor configuration.
They use its Lua `hl` API, not legacy `.conf` syntax.

| File | Purpose |
| --- | --- |
| [ghost-rules.lua](../config/hypr/ghost-rules.lua) | Settings geometry, QML-owned layer animation and floating clipse terminal |
| [ghost-autostart.lua](../config/hypr/ghost-autostart.lua) | Start the installed ghOSt wrapper once; optional wallpaper/clipboard helpers |
| [ghost-controls.lua](../config/hypr/ghost-controls.lua) | Settings, screenshot, audio and brightness shortcuts |
| [ghost-migration.lua](../config/hypr/ghost-migration.lua) | Launcher, reload, Settings pages, Zed, clipse and workspace shortcuts |
| [ghost-lock.lua](../config/hypr/ghost-lock.lua) | Existing Super+L/power-key route to ghOSt lock; no lock is executed when loading |

## Load deliberately

After installing ghOSt, copy only the snippets you need into a `ghost` folder
inside your Hyprland configuration directory. To load rules and autostart:

```lua
local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
dofile(config .. "/hypr/ghost/ghost-rules.lua")
dofile(config .. "/hypr/ghost/ghost-autostart.lua")
```

First remove or skip duplicate **ghOSt-owned** entries. `install.sh --activate`
already adds shell startup, its main no-animation rule and Settings window rule;
the example above is an alternative manual route, not another block to append
after installer activation. Preserve unrelated startup and rules.

If not already started elsewhere, the optional helpers can be enabled before
loading the autostart module:

```lua
ghostAutostart = { wallpaperDaemon = true, clipboardListener = true }
```

They require existing `awww` and `clipse` installations. The default starts only
the ghOSt wrapper created by `install.sh --activate`; it does not change the
wallpaper, stop another shell or enable user services.

Shortcut modules are optional. Replace existing matching combinations rather
than loading duplicate bindings. The supplied routes preserve the inspected live
keys: Super+Space launcher, Super+I Settings, Super+A Zed, Super+V clipse,
Super+B wallpaper, Super+N network Settings, Super+R/H Info, Super+M reload,
Super+number workspaces, Super+Shift+number move to workspace, Super+scroll
workspace wheel, screenshot/media/brightness keys and Super+L lock.
The snippets do not install applications or execute session actions as tests.
`ghost-rules.lua` supplies the lock exit rule; `ghost-lock.lua` no longer repeats it.

## Intentionally not exported

Monitor modes/output selection, GPU/driver/environment overrides, saturation
settings, personal app shortcuts, user services, account paths and unrelated
autostart were not copied. Keep your own configuration for those areas.
The old `config/hypr/hyprland.lua` is a historical standalone study containing
machine-specific/global policies, not a recommended live configuration.

Lua syntax and mocked API tests check the new modules without calling Hyprland,
starting services, changing bindings or locking a session. This publication does
not change or reload the active laptop configuration.
