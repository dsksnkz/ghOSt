import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "EdgeVolume.js" as EdgeVolume

// Full-height two-pixel edge; no keyboard grab or motion polling.
PanelWindow {
    id: edge
    property string side: "left"
    // Tiny activation strip; only an already-open OSD gets a forgiving exit range.
    readonly property real factor: Theme.scaleFor(screen)
    implicitWidth: hold.latched ? Math.round(72 * factor) : 2
    implicitHeight: EdgeVolume.bounds(screen.height).height
    anchors { top: true; left: side === "left"; right: side === "right" }
    margins.top: EdgeVolume.bounds(screen.height).top
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-volume-edge-" + side
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    readonly property var monitor: Hyprland.monitorFor(screen)
    // Once open, the strip keeps it open only beside the card: moving up or
    // down along the edge, away from it, closes it like leaving the edge.
    readonly property real cardTop: EdgeVolume.osdTop(screen.height, Math.round(310 * factor), OsdState.pointerY) + 8 * factor
    // Closed by moving along the edge: it opens again only after the pointer
    // has left the edge sideways, not at the new spot further along.
    property bool blocked: false
    readonly property bool nearCard: hit.mouseY > cardTop - 40 * factor && hit.mouseY < cardTop + 334 * factor
    FullscreenState { id: fullscreenState; monitor: edge.monitor }
    visible: !fullscreenState.active

    EdgeHold {
        id: hold
        hovered: edge.visible && !edge.blocked && (hit.containsMouse && (!hold.latched || edge.nearCard) ||
            (OsdState.ownsEdge(edge.screen.name, edge.side) &&
                (OsdState.cardHovered || OsdState.interacting)))
        pointerY: edge.margins.top + hit.mouseY
        onActivated: y => OsdState.holdEdge(edge.screen.name, edge.side, y)
        onReleased: {
            edge.blocked = hit.containsMouse;
            OsdState.releaseEdge(edge.screen.name, edge.side);
        }
    }
    mask: Region {
        width: edge.width
        height: edge.height
        // Let the OSD's own input receive hover, wheel and slider drags.
        Region {
            x: 14 * edge.factor
            y: EdgeVolume.osdTop(edge.screen.height, Math.round(310 * edge.factor), OsdState.pointerY) + 8 * edge.factor
            width: OsdState.ownsEdge(edge.screen.name, edge.side) ? 44 * edge.factor : 0
            height: 294 * edge.factor
            intersection: Intersection.Subtract
        }
    }
    Component.onDestruction: OsdState.releaseEdge(edge.screen?.name || "", edge.side)
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: if (!containsMouse)
            edge.blocked = false
        onWheel: event => {
            // Scrolling/clicking must not bypass the 200ms dwell.
            if (hold.latched && OsdState.ownsEdge(edge.screen.name, edge.side))
                OsdState.move(EdgeVolume.step(Desk.volume, event.angleDelta.y));
            event.accepted = true;
        }
    }
}
