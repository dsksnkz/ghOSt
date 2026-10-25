import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "EdgeVolume.js" as EdgeVolume

// Full-height two-pixel edge; no sidebar action, keyboard grab or motion polling.
PanelWindow {
    id: edge
    property string side: "left"
    // Tiny activation strip; only an already-open OSD gets a forgiving exit range.
    implicitWidth: hold.latched ? 72 : 2
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

    EdgeHold {
        id: hold
        hovered: edge.visible && (hit.containsMouse ||
            (OsdState.ownsEdge(edge.screen.name, edge.side) &&
                (OsdState.cardHovered || OsdState.interacting)))
        pointerY: edge.margins.top + hit.mouseY
        onActivated: y => OsdState.holdEdge(edge.screen.name, edge.side, y)
        onReleased: OsdState.releaseEdge(edge.screen.name, edge.side)
    }
    mask: Region {
        width: edge.width
        height: edge.height
        // Let the OSD's own input receive hover, wheel and slider drags.
        Region {
            x: 14
            y: EdgeVolume.osdTop(edge.screen.height, 310, OsdState.pointerY) + 8
            width: OsdState.ownsEdge(edge.screen.name, edge.side) ? 44 : 0
            height: 294
            intersection: Intersection.Subtract
        }
    }
    Component.onDestruction: OsdState.releaseEdge(edge.screen?.name || "", edge.side)
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        onWheel: event => {
            // Scrolling/clicking must not bypass the 200ms dwell.
            if (hold.latched && OsdState.ownsEdge(edge.screen.name, edge.side))
                OsdState.move(EdgeVolume.step(Desk.volume, event.angleDelta.y));
            event.accepted = true;
        }
    }
}
