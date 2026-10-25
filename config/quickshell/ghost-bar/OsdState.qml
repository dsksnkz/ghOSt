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
    property string edgeSide: "left"
    // Screen-local logical Y. Negative means a non-pointer/keyboard OSD.
    property real pointerY: -1
    property bool edgeHeld: false
    property bool cardHovered: false
    property var brightness: null
    property int lastBrightness: -1
    property real pendingBrightness: 0
    readonly property real amount: kind === "brightness" ? brightness ?? 0 : Desk.volume
    readonly property bool available: kind === "brightness" ? brightness !== null : !!Desk.audio
    function ownsEdge(targetScreen, side) {
        return edgeHeld && screenName === targetScreen && edgeSide === side;
    }
    function holdEdge(targetScreen, side, y) {
        if (ownsEdge(targetScreen, side))
            return;
        show("volume", targetScreen, side, y);
        edgeHeld = true;
        expiry.stop();
    }
    function releaseEdge(targetScreen, side) {
        if (!ownsEdge(targetScreen, side))
            return;
        edgeHeld = false;
        cardHovered = false;
        opened = false;
        expiry.stop();
    }
    function keepVisible() {
        if (edgeHeld)
            expiry.stop();
        else
            expiry.restart();
    }
    function show(value, targetScreen = "", side = "", y = -1) {
        // Audio callbacks during edge scrolling must preserve its latched origin.
        if (edgeHeld && !side && value === "volume") {
            opened = true;
            return;
        }
        edgeHeld = false;
        if (side) {
            edgeSide = side;
            pointerY = Number.isFinite(y) ? y : -1;
        } else if (!opened) {
            edgeSide = "left";
            pointerY = -1;
        }
        kind = value;
        screenName = targetScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || "";
        opened = true;
        keepVisible();
    }
    function request(value) {
        if (value === "brightness") {
            if (!readBrightness.running)
                readBrightness.running = true;
        } else if (value === "volume")
            show(value);
    }
    function move(value) {
        keepVisible();
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
        onTriggered: if (osd.edgeHeld)
            stop()
        else if (osd.interacting)
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
