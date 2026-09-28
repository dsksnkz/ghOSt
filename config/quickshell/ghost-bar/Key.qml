import QtQuick
import QtQuick.Controls as Controls

Rectangle {
    id: root
    property string text: ""
    property string hint: ""
    property bool selected: false
    property color ink: selected ? Theme.base : Theme.text
    property real padding: 12
    property alias hovered: mouse.containsMouse
    signal clicked()
    signal secondaryClicked()
    signal scrolled(real delta)
    implicitWidth: label.implicitWidth + padding * 2
    implicitHeight: 30
    radius: 5
    color: selected ? Theme.cream : mouse.pressed ? Theme.line : mouse.containsMouse ? Theme.raised : "transparent"
    scale: mouse.pressed ? 0.96 : 1
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
    Label { id: label; anchors.centerIn: parent; text: root.text; color: root.ink }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.LeftButton ? root.clicked() : root.secondaryClicked()
        onWheel: event => root.scrolled(event.angleDelta.y)
    }
    Controls.ToolTip.visible: mouse.containsMouse && root.hint !== ""
    Controls.ToolTip.delay: 550
    Controls.ToolTip.text: hint
    Accessible.role: Accessible.Button
    Accessible.name: hint || text
    Accessible.onPressAction: clicked()
}
