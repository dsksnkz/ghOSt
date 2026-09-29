import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 48
    exclusiveZone: 48
    color: "transparent"
    WlrLayershell.namespace: "ghost-bar"
    WlrLayershell.layer: WlrLayer.Top
    Rail { anchors.fill: parent; monitor: Hyprland.monitorFor(bar.screen); trayWindow: bar; screenName: bar.screen.name }
}
