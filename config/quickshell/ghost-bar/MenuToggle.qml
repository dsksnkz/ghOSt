import QtQuick

// The Wi-Fi and Bluetooth menus' switch: a dark track with a light knob that slides across.
Item {
    id: toggle
    property bool checked: false
    property string hint: ""
    signal toggled(bool value)
    implicitWidth: 58
    implicitHeight: 27
    opacity: enabled ? 1 : .45
    Accessible.role: Accessible.CheckBox
    Accessible.name: hint
    Accessible.checked: checked
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#282828"
    }
    Rectangle {
        x: toggle.checked ? toggle.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 23
        radius: height / 2
        color: toggle.checked ? "#dfdfdf" : "#8a8a8a"
        Behavior on x {
            NumberAnimation {
                duration: Theme.reducedMotion ? 0 : 160
                easing.type: Easing.OutCubic
            }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.reducedMotion ? 0 : 160 }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled(!toggle.checked)
    }
}
