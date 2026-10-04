import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: sidebar

    property var companion
    property var peers: []
    property bool managedFocus: false
    property bool opened: false
    property real reveal: opened ? 1 : 0
    readonly property real designScale: screen.width / 1920

    function sync() {
        opened = Desk.sidebarOpen && Desk.panelScreen === screen.name;
    }

    Component.onCompleted: sync()
    margins.left: 0
    margins.top: 144 * designScale
    implicitWidth: Math.min(356 * designScale, screen.width - 32)
    implicitHeight: Math.min(794 * designScale, screen.height - margins.top - 14)
    color: "transparent"
    visible: opened || reveal > 0.001
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-sidebar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    onOpenedChanged: {
        if (opened)
            Qt.callLater(() => {
                content.forceActiveFocus();
                if (!sidebar.managedFocus)
                    grab.active = true;
            });
        else if (!sidebar.managedFocus)
            grab.active = false;

        if (Desk.wifi)
            Desk.wifi.scannerEnabled = opened || Desk.panel === "network";
    }

    Connections {
        function onSidebarOpenChanged() {
            sidebar.sync();
        }

        function onPanelScreenChanged() {
            sidebar.sync();
        }

        target: Desk
    }

    anchors {
        top: true
        left: true
    }

    HyprlandFocusGrab {
        id: grab

        windows: sidebar.peers.length ? [sidebar].concat(sidebar.peers) : sidebar.companion ? [sidebar, sidebar.companion] : [sidebar]
        onCleared: Qt.callLater(() => {
            if (!sidebar.managedFocus && sidebar.opened)
                Desk.sidebarOpen = false;
        })
    }

    SidebarFigmaBody {
        id: content

        x: 0
        y: 2 * sidebar.designScale
        width: sidebar.width - 2 * sidebar.designScale
        height: sidebar.height - 4 * sidebar.designScale
        screen: sidebar.screen
        opened: sidebar.opened
        reveal: sidebar.reveal
        onCloseRequested: Desk.sidebarOpen = false
    }

    Behavior on reveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : 280
            easing.type: Easing.OutCubic
        }
    }
}
