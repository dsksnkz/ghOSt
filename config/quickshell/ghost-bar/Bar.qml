import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: bar

    readonly property var monitor: Hyprland.monitorFor(screen)
    visible: !fullscreenState.active
    implicitHeight: 64 * screen.width / 1920
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "ghost-bar"
    // Keep normal controls above other shells; fullscreen unmaps this surface.
    WlrLayershell.layer: WlrLayer.Overlay

    FullscreenState {
        id: fullscreenState
        monitor: bar.monitor
    }

    anchors {
        top: true
        left: true
        right: true
    }

    Rail {
        anchors.fill: parent
        monitor: bar.monitor
        trayWindow: bar
        screenName: bar.screen.name
    }
}
