import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// An inert native surface BELOW production overlays. Never dispatches actions
// into the user's applications when a dismissal region incorrectly passes through.
ShellRoot {
    id: root
    property int presses: 0
    // Fail closed: never leave this diagnostic screen on the user's desktop.
    Timer {
        interval: 5000
        running: true
        onTriggered: Qt.quit()
    }
    PanelWindow {
        color: "#202020"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "ghost-input-check"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.presses++
        }
        Text {
            anchors.centerIn: parent
            text: "Outside-click check"
            color: "#dddddd"
        }
    }
    IpcHandler {
        target: "input-check"
        function status(): string {
            return JSON.stringify({
                presses: root.presses
            });
        }
        function stop(): void {
            Qt.quit();
        }
    }
}
