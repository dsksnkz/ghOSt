import QtQuick

// Shared by the native top popup and the isolated, captureable preview.
G2Surface {
    id: banner
    property var notification: null
    signal activated
    signal dismissed
    implicitWidth: 360
    implicitHeight: Math.min(180, body.height + 32)
    radius: 15
    smoothing: .6
    color: "#252525"
    border.width: 1
    border.color: "#555555"
    Column {
        id: body
        x: 16
        y: 16
        width: banner.width - 52
        spacing: 7
        Label {
            width: parent.width
            text: banner.notification?.app || ""
            font.pixelSize: 9
            color: Theme.muted
            textFormat: Text.PlainText
        }
        Label {
            width: parent.width
            text: banner.notification?.summary || ""
            font.pixelSize: 12
            font.weight: Font.Bold
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
        Label {
            width: parent.width
            text: banner.notification?.body || ""
            font.pixelSize: 10
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 4
            visible: text !== ""
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: banner.activated()
    }
    Key {
        x: parent.width - 28
        y: 5
        width: 24
        height: 24
        radius: 8
        text: "×"
        hint: "Close notification banner"
        onClicked: banner.dismissed()
    }
}
