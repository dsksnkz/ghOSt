import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    property var displayScreen
    screen: displayScreen
    visible: Notifications.mode === "server" && Notifications.toast !== null && !Notifications.dnd
    anchors {
        top: true
        right: true
    }
    margins.top: 76
    margins.right: 20
    implicitWidth: 330
    implicitHeight: Math.min(180, body.height + 32)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-notification"
    WlrLayershell.layer: WlrLayer.Overlay
    G2Surface {
        anchors.fill: parent
        radius: 15
        color: "#252525"
        border.width: 1
        border.color: "#4d4d4d"
        Column {
            id: body
            x: 16
            y: 16
            width: 280
            spacing: 7
            Label {
                width: parent.width
                text: Notifications.toast?.app || ""
                font.pixelSize: 9
                color: Theme.muted
                textFormat: Text.PlainText
            }
            Label {
                width: parent.width
                text: Notifications.toast?.summary || ""
                font.pixelSize: 12
                font.weight: Font.Bold
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }
            Label {
                width: parent.width
                text: Notifications.toast?.body || ""
                font.pixelSize: 10
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 4
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                Desk.toggleSidebar(displayScreen.name);
                Notifications.toast = null;
            }
        }
        Key {
            x: parent.width - 28
            y: 5
            width: 24
            height: 24
            radius: 8
            text: "×"
            hint: "Close notification banner"
            onClicked: Notifications.toast = null
        }
    }
}
