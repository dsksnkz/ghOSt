import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower

PanelWindow {
    id: panelWindow
    property var companion
    property string page: ""
    property bool opened: false
    property real reveal: opened ? 1 : 0
    function syncPanel() {
        const show = Desk.panel !== "" && Desk.panelScreen === screen.name;
        if (show) page = Desk.panel;
        opened = show;
    }
    onOpenedChanged: {
        Qt.callLater(() => {
            if (opened) content.focusPage();
            focusGrab.active = opened;
        });
    }
    Component.onCompleted: syncPanel()
    Connections {
        target: Desk
        function onPanelChanged() { panelWindow.syncPanel(); }
        function onPanelScreenChanged() { panelWindow.syncPanel(); }
    }
    anchors { top: true; left: true }
    margins.top: 52
    margins.left: Math.round(Math.max(6, Math.min(screen.width - 398, Desk.panelX)))
    implicitWidth: Math.min(392, screen.width - 12)
    implicitHeight: content.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    visible: opened || reveal > 0.001
    Behavior on reveal { NumberAnimation { duration: Theme.panel; easing.type: Easing.OutCubic } }
    HyprlandFocusGrab { id: focusGrab; windows: panelWindow.companion ? [panelWindow, panelWindow.companion] : [panelWindow]; onCleared: Qt.callLater(Desk.close) }
    PanelContent { id: content; anchors.fill: parent; popup: panelWindow }
}
