import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: bar

    readonly property var monitor: Hyprland.monitorFor(screen)
    visible: !fullscreenState.active
    implicitHeight: Math.ceil(Theme.railHeight * screen.width / 1920)
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

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: if (Desk.sidebarOpen || Desk.panel === "calendar")
            Desk.close()
    }

    Rail {
        active: bar.visible
        anchors.fill: parent
        monitor: bar.monitor
        trayWindow: bar
        screenName: bar.screen.name
    }
}
