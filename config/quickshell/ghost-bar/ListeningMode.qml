import QtQuick

// AirPods listening modes as three equal buttons. The buds do not report their
// current mode on this link, so one is highlighted once it has been chosen.
Row {
    id: control
    property real buttonHeight: 32
    visible: AirPods.ready
    spacing: 16
    Repeater {
        model: AirPods.modes
        Rectangle {
            id: button
            required property var modelData
            readonly property bool selected: AirPods.state.mode === modelData.id
            width: (control.width - control.spacing * (AirPods.modes.length - 1)) / AirPods.modes.length
            height: control.buttonHeight
            radius: 8
            color: selected ? "#d9d9d9" : area.containsMouse ? "#4f4f4f" : "#454545"
            Behavior on color {
                ColorAnimation { duration: Theme.reducedMotion ? 0 : 160 }
            }
            Accessible.role: Accessible.Button
            Accessible.name: modelData.name
            Text {
                anchors.centerIn: parent
                width: parent.width - 12
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: button.modelData.name
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Theme.mediumWeight
                color: button.selected ? "#111111" : "#ffffff"
                Behavior on color {
                    ColorAnimation { duration: Theme.reducedMotion ? 0 : 160 }
                }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AirPods.setMode(button.modelData.id)
            }
        }
    }
}
