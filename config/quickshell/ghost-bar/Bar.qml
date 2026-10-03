import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 64 * screen.width / 1920
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "ghost-bar"
    WlrLayershell.layer: WlrLayer.Overlay
    Rail { anchors.fill: parent; monitor: Hyprland.monitorFor(bar.screen); trayWindow: bar; screenName: bar.screen.name }
}
