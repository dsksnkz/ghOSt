-- Execute only against a recording API; never call the compositor or a shell.
local root = assert(arg[1], "repository root required")
local calls = { binds = {}, layers = {}, windows = {}, configs = {}, hooks = {}, commands = {} }
hl = {
    bind = function(key, action, options)
        assert(not calls.binds[key], "duplicate shortcut: " .. key)
        calls.binds[key] = { action = action, options = options }
    end,
    layer_rule = function(rule) calls.layers[#calls.layers + 1] = rule end,
    window_rule = function(rule) calls.windows[#calls.windows + 1] = rule end,
    config = function(config) calls.configs[#calls.configs + 1] = config end,
    on = function(event, callback)
        assert(event == "hyprland.start")
        calls.hooks[#calls.hooks + 1] = callback
    end,
    exec_cmd = function(command) calls.commands[#calls.commands + 1] = command end,
    dsp = {
        exec_cmd = function(command) return { command = command } end,
        focus = function(options) return { focus = options } end,
        window = { move = function(options) return { move = options } end }
    }
}
local function load(name) dofile(root .. "/config/hypr/" .. name .. ".lua") end
load("ghost-rules")
load("ghost-controls")
load("ghost-migration")
load("ghost-lock")
load("ghost-autostart")
assert(#calls.commands == 0, "loading snippets executed a command")
assert(#calls.layers == 2 and #calls.windows == 3)
assert(calls.layers[1].no_anim and calls.layers[2].no_anim)
assert(calls.windows[1].name == "ghost-settings" and calls.windows[1].size[1] == 1024)
assert(calls.windows[2].name == "ghost-intro" and calls.windows[2].float)
assert(calls.windows[2].suppress_event == "maximize fullscreen")
assert(calls.windows[3].match.class == "^clipse$" and calls.windows[3].size[1] == 900)
assert(calls.binds["SUPER + Space"].action.command:match("toggle launcher$"))
assert(calls.binds["SUPER + A"].action.command == "zeditor")
assert(calls.binds["SUPER + V"].action.command == "kitty --start-as=normal --class clipse -e clipse")
assert(calls.binds["SUPER + I"].action.command:match("settings general$"))
assert(calls.binds["SUPER + SHIFT + S"].action.command == "hyprshot -m region")
assert(calls.binds["SUPER + L"].action.command:find("ghost%-bar/lock.qml"))
assert(calls.binds["SUPER + mouse_up"].action.command:match('workspace_scroll.py" %-1$'))
assert(calls.binds["SUPER + mouse_down"].action.command:match('workspace_scroll.py" 1$'))
assert(calls.binds["SUPER + 0"].action.focus.workspace == 10)
assert(calls.binds["SUPER + SHIFT + 0"].action.move.workspace == 10)
assert(#calls.configs == 1 and calls.configs[1].binds.scroll_event_delay == 10)
assert(#calls.hooks == 1)
calls.hooks[1]()
assert(#calls.commands == 1 and calls.commands[1]:find('/.local/bin/ghost%-bar'))
ghostAutostart = { wallpaperDaemon = true, clipboardListener = true }
load("ghost-autostart")
calls.commands = {}
calls.hooks[2]()
assert(#calls.commands == 3)
assert(calls.commands[2] == "awww-daemon" and calls.commands[3] == "clipse -listen")
print("PASS: scoped Hyprland rules, unique shortcuts, portable paths and opt-in helper startup")
