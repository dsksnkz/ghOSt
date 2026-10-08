pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: osd
    property bool opened: false
    property bool armed: false
    property bool interacting: false
    property string kind: "volume"
    property string screenName: ""
    property var brightness: null
    property int lastBrightness: -1
    property real pendingBrightness: 0
    readonly property real amount: kind === "brightness" ? brightness ?? 0 : Desk.volume
    readonly property bool available: kind === "brightness" ? brightness !== null : !!Desk.audio
    function show(value) {
        kind = value;
        screenName = Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        opened = true;
        expiry.restart();
    }
    function request(value) {
        if (value === "brightness") {
            if (!readBrightness.running)
                readBrightness.running = true;
        } else if (value === "volume")
            show(value);
    }
    function move(value) {
        expiry.restart();
        if (kind === "volume")
            Desk.setVolume(value / 100);
        else {
            pendingBrightness = Math.max(1, Math.min(100, value));
            brightness = pendingBrightness;
            commit.restart();
        }
    }
    Connections {
        target: Desk
        function onVolumeChanged() {
            if (osd.armed)
                osd.show("volume");
        }
        function onMutedChanged() {
            if (osd.armed)
                osd.show("volume");
        }
    }
    Connections {
        target: Settings
        function onStateChanged() {
            const value = Settings.state.brightness?.percent;
            if (typeof value !== "number")
                return;
            if (osd.lastBrightness >= 0 && osd.lastBrightness !== value && osd.armed) {
                osd.brightness = value;
                osd.show("brightness");
            }
            osd.lastBrightness = value;
        }
    }
    Timer {
        interval: 800
        running: true
        onTriggered: osd.armed = true
    }
    Timer {
        id: expiry
        interval: 2200
        onTriggered: if (osd.interacting)
            restart()
        else
            osd.opened = false
    }
    Timer {
        id: commit
        interval: 100
        onTriggered: {
            if (writeBrightness.running) {
                restart();
                return;
            }
            writeBrightness.command = ["brightnessctl", "set", Math.round(osd.pendingBrightness) + "%"];
            writeBrightness.running = true;
        }
    }
    Process {
        id: readBrightness
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                const value = Number(fields[3]?.replace("%", ""));
                osd.brightness = fields[1] === "backlight" && Number.isFinite(value) ? value : null;
                osd.show("brightness");
            }
        }
    }
    Process {
        id: writeBrightness
    }
}
