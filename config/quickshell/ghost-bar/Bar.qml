import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: bar

    implicitHeight: 64 * screen.width / 1920
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "ghost-bar"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
        right: true
    }

    Rail {
        anchors.fill: parent
        monitor: Hyprland.monitorFor(bar.screen)
        trayWindow: bar
        screenName: bar.screen.name
    }
}
