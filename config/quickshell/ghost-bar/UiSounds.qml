pragma Singleton
import QtMultimedia
import QtQuick
import Quickshell

QtObject {
    id: sounds
    readonly property bool silent: Quickshell.env("GHOST_SETTINGS_FIXTURE") === "1" || Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1"
    readonly property var defaults: ({enabled: true, volume: 18, presets: {rail: "rail", sidebar: "sidebar", settings: "settings"}, files: {}})
    readonly property var choices: [
        {id: "rail", name: "Soft pop"},
        {id: "sidebar", name: "Low tap"},
        {id: "settings", name: "Light tick"},
        {id: "none", name: "Off"},
        {id: "custom", name: "Custom WAV"}
    ]
    readonly property var preferences: Settings.state.preferences?.sounds || defaults
    readonly property int level: Math.max(0, Math.min(100, Math.round(preferences.volume ?? 18)))
    readonly property bool enabled: preferences.enabled !== false
    property double lastClick: 0
    readonly property SoundEffect rail: SoundEffect {
        source: sounds.sourceFor("rail")
        volume: sounds.level / 100
        muted: sounds.silent
    }

    readonly property SoundEffect sidebar: SoundEffect {
        source: sounds.sourceFor("sidebar")
        volume: sounds.level / 100
        muted: sounds.silent
    }

    readonly property SoundEffect settings: SoundEffect {
        source: sounds.sourceFor("settings")
        volume: sounds.level / 100
        muted: sounds.silent
    }

    function preset(group) {
        return preferences.presets?.[group] ?? defaults.presets[group];
    }
    function sourceFor(group) {
        const selected = preset(group);
        if (selected === "none")
            return "";
        if (selected === "custom")
            return preferences.files?.[group] || "";
        return "file://" + Quickshell.shellPath("sounds/" + selected + ".wav");
    }
    function effectFor(group) {
        return group === "rail" ? rail : group === "sidebar" ? sidebar : group === "settings" ? settings : null;
    }
    function allowed(group) {
        return !!effectFor(group) && enabled && level > 0 && !!sourceFor(group);
    }
    function warning(group) {
        const effect = effectFor(group);
        return effect?.status === SoundEffect.Error ? "Sound unavailable. Choose another WAV." : "";
    }
    function ready(group) {
        return effectFor(group)?.status === SoundEffect.Ready;
    }

    function play(group) {
        const now = Date.now();
        if (silent || !allowed(group) || now - lastClick < 45)
            return false;

        const effect = effectFor(group);
        if (effect.status === SoundEffect.Ready) {
            lastClick = now;
            effect.play();
            return true;
        }
        return false;
    }
    function status() {
        return {
            rail: rail.status,
            sidebar: sidebar.status,
            settings: settings.status,
            volume: rail.volume,
            enabled,
            presets: preferences.presets || defaults.presets,
            silent
        };
    }
}
