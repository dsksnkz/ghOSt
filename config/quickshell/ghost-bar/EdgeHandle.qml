import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "EdgeVolume.js" as EdgeVolume

// A two-pixel, full-height edge target. No sidebar action or keyboard grab.
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
    FullscreenState { id: fullscreenState; monitor: edge.monitor }
    visible: !fullscreenState.active
    function revealAt(y) {
        OsdState.show("volume", edge.screen.name, edge.side, edge.margins.top + y);
    }
    property real pendingPointerY: -1
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        onEntered: dwell.restart()
        onExited: {
            dwell.stop();
            pointerUpdate.stop();
        }
        onPositionChanged: mouse => {
            if (containsMouse && OsdState.opened && !OsdState.interacting
                    && OsdState.kind === "volume" && OsdState.edgeSide === edge.side
                    && OsdState.screenName === edge.screen.name) {
                edge.pendingPointerY = edge.margins.top + mouse.y;
                if (!pointerUpdate.running)
                    pointerUpdate.start();
            }
        }
        onWheel: event => {
            edge.revealAt(event.y);
            OsdState.move(EdgeVolume.step(Desk.volume, event.angleDelta.y));
            event.accepted = true;
        }
        onClicked: mouse => edge.revealAt(mouse.y)
        Timer {
            id: pointerUpdate
            interval: 16
            onTriggered: {
                if (hit.containsMouse && OsdState.opened && !OsdState.interacting
                        && OsdState.edgeSide === edge.side && OsdState.screenName === edge.screen.name)
                    OsdState.pointerY = edge.pendingPointerY;
            }
        }
        Timer {
            id: dwell
            interval: 120
            onTriggered: if (hit.containsMouse)
                edge.revealAt(hit.mouseY)
        }
    }
}
