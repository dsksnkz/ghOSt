import QtQuick

Item {
    property color ink: Theme.text
    implicitWidth: 24
    implicitHeight: 24
    FontLoader { id: face; source: "fonts/TurretRoad-Bold.ttf" }
    Text {
        anchors.centerIn: parent
        text: "G"
        color: parent.ink
        font.family: face.status === FontLoader.Ready ? face.name : Theme.font
        font.pixelSize: parent.height
        font.weight: Font.Bold
        renderType: Text.QtRendering
    }
}
