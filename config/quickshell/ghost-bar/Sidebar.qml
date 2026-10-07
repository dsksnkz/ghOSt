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
    readonly property real screenScale: screen.width / 1920
    readonly property int topOffset: Math.ceil((Theme.railHeight + 8) * screenScale)
    // Anchor below the rail, then fit the enlarged coordinate plane uniformly.
    readonly property real designScale: Math.min(screenScale * 1.15,
        (screen.width - 32) / 356,
        Math.max(1, screen.height - topOffset - 14) / 794)

    function sync() {
        opened = Desk.sidebarOpen && Desk.panelScreen === screen.name;
    }

    Component.onCompleted: sync()
    margins.left: 0
    margins.top: topOffset
    implicitWidth: Math.ceil(356 * designScale)
    implicitHeight: Math.ceil(794 * designScale)
    color: "transparent"
    visible: opened || reveal > 0.001
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-sidebar"
    WlrLayershell.layer: WlrLayer.Overlay
    // Opening from a keyboard-less rail must focus the sidebar immediately.
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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
