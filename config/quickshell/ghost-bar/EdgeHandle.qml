import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "EdgeVolume.js" as EdgeVolume

// A two-pixel, middle-only edge target. No sidebar action or broad input mask.
PanelWindow {
    id: edge
    property string side: "left"
    implicitWidth: 2
    implicitHeight: EdgeVolume.bounds(screen.height).height
    anchors { top: true; left: side === "left"; right: side === "right" }
    margins.top: EdgeVolume.bounds(screen.height).top
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-volume-edge-" + side
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    readonly property var monitor: Hyprland.monitorFor(screen)
    visible: !(monitor?.activeWorkspace?.hasFullscreen ?? false)
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        onEntered: dwell.restart()
        onExited: dwell.stop()
        onWheel: event => {
            OsdState.show("volume", edge.screen.name, edge.side);
            OsdState.move(EdgeVolume.step(Desk.volume, event.angleDelta.y));
            event.accepted = true;
        }
        onClicked: OsdState.show("volume", edge.screen.name, edge.side)
        Timer {
            id: dwell
            interval: 120
            onTriggered: if (hit.containsMouse)
                OsdState.show("volume", edge.screen.name, edge.side)
        }
    }
}
