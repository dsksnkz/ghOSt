pragma Singleton
import QtMultimedia
import QtQuick
import Quickshell

QtObject {
    readonly property bool silent: Quickshell.env("GHOST_SETTINGS_FIXTURE") === "1" || Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1"
    property double lastClick: 0
    readonly property SoundEffect rail: SoundEffect {
        source: "file://" + Quickshell.shellPath("sounds/rail.wav")
        volume: 0.18
    }

    readonly property SoundEffect sidebar: SoundEffect {
        source: "file://" + Quickshell.shellPath("sounds/sidebar.wav")
        volume: 0.18
    }

    readonly property SoundEffect settings: SoundEffect {
        source: "file://" + Quickshell.shellPath("sounds/settings.wav")
        volume: 0.18
    }

    function play(group) {
        const now = Date.now();
        if (silent || now - lastClick < 45)
            return;

        const effect = group === "rail" ? rail : group === "sidebar" ? sidebar : settings;
        if (effect.status === SoundEffect.Ready) {
            lastClick = now;
            effect.play();
        }
    }
    function status() {
        return {
            rail: rail.status,
            sidebar: sidebar.status,
            settings: settings.status,
            volume: rail.volume
        };
    }
}
