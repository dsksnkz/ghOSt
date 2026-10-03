import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Reserve the rail's work area independently of its screen-edge overlay.
// Other shells may already reserve part of that area; never double-count it.
PanelWindow {
    id: reservation
    property bool measured: false
    visible: measured
    anchors { top: true; left: true; right: true }
    implicitHeight: 1
    readonly property int requiredSpace: Math.ceil(64 * screen.width / 1920)
    property int otherSpace: requiredSpace
    exclusiveZone: Math.max(0, requiredSpace - otherSpace)
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "ghost-rail-reservation"
    WlrLayershell.layer: WlrLayer.Top
    // A content item ensures a buffer is committed even for an input-empty,
    // completely transparent reservation surface.
    Item { width: 1; height: 1 }
    Process {
        id: readWorkarea
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const monitor = JSON.parse(text).find(m => m.name === reservation.screen.name);
                const total = monitor?.reserved?.[1];
                const own = reservation.measured ? reservation.exclusiveZone : 0;
                if (typeof total === "number" && total >= own) {
                    reservation.otherSpace = Math.max(0, total-own);
                    reservation.measured = true;
                }
            } catch (_) {}
        } }
    }
    Timer { interval: 150; running: true; onTriggered: readWorkarea.running=true }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: readWorkarea.running=true }
}
