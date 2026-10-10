import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: panelWindow

    property var companion
    property bool managedFocus: false
    property string page: ""
    property bool opened: false
    property real reveal: opened ? 1 : 0

    function syncPanel() {
        const show = Desk.panel !== "" && Desk.panel !== "calendar" && Desk.panelScreen === screen.name;
        if (show)
            page = Desk.panel;

        opened = show;
    }

    onOpenedChanged: {
        Qt.callLater(() => {
            if (opened)
                content.focusPage();

            if (!panelWindow.managedFocus)
                focusGrab.active = opened;
        });
    }
    Component.onCompleted: syncPanel()
    margins.top: page === "calendar" ? 82 : 68
    margins.left: page === "calendar" || page === "launcher" ? Math.round((screen.width - implicitWidth) / 2) : Math.round(Math.max(6, Math.min(screen.width - 398, Desk.panelX)))
    implicitWidth: page === "calendar" ? Math.floor(Math.min(screen.width * 733 / 1920, (screen.height - 100) * 1200 / 505)) : Math.min(page === "launcher" ? 600 : 392, screen.width - 12)
    implicitHeight: content.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    visible: opened || reveal > 0.001

    Connections {
        function onPanelChanged() {
            panelWindow.syncPanel();
        }

        function onPanelScreenChanged() {
            panelWindow.syncPanel();
        }

        target: Desk
    }

    anchors {
        top: true
        left: true
    }

    HyprlandFocusGrab {
        id: focusGrab

        windows: panelWindow.companion ? [panelWindow, panelWindow.companion] : [panelWindow]
        onCleared: {
            if (!panelWindow.managedFocus) {
                Qt.callLater(Desk.close);
            }
        }
    }

    PanelContent {
        id: content

        anchors.fill: parent
        popup: panelWindow
    }

    Behavior on reveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : Theme.panel
            easing.type: Easing.OutCubic
        }
    }
}
