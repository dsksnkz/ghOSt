import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: sidebar
    property var companion
    property alias settingsOpen: content.settingsOpen
    property bool opened: false
    property real reveal: opened ? 1 : 0
    function sync() { opened = Desk.sidebarOpen && Desk.panelScreen === screen.name; }
    Component.onCompleted: sync()
    Connections {
        target: Desk
        function onSidebarOpenChanged() { sidebar.sync(); }
        function onPanelScreenChanged() { sidebar.sync(); }
        function onSettingsRequestedChanged() {
            if (Desk.settingsRequested && sidebar.opened) sidebar.settingsOpen = true;
        }
    }
    anchors { top: true; left: true }
    margins.left: 16
    margins.top: 82
    implicitWidth: Math.min(360, screen.width - 32)
    implicitHeight: Math.min(800, screen.height - 104)
    color: "transparent"
    visible: opened || reveal > .001
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-sidebar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on reveal {
        NumberAnimation { duration: Theme.reducedMotion ? 0 : 210; easing.type: Easing.OutCubic }
    }
    onOpenedChanged: {
        if (opened) Qt.callLater(() => {
            content.forceActiveFocus();
            grab.active = true;
            if (Desk.settingsRequested) settingsOpen = true;
        });
        else { grab.active = false; settingsOpen = false; }
        if (Desk.wifi) Desk.wifi.scannerEnabled = opened || Desk.panel === "network";
    }
    HyprlandFocusGrab {
        id: grab
        windows: sidebar.companion ? [sidebar, sidebar.companion] : [sidebar]
        onCleared: Qt.callLater(() => { if (sidebar.opened) Desk.sidebarOpen = false; })
    }
    SidebarBody {
        id: content
        anchors.fill: parent
        screen: sidebar.screen
        opened: sidebar.opened
        reveal: sidebar.reveal
        onCloseRequested: Desk.sidebarOpen = false
    }
}
