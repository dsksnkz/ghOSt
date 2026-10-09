import QtQuick
import QtQuick.Controls as Controls

G2Surface {
    id: root

    property string text: ""
    property string hint: ""
    property bool selected: false
    property color ink: selected ? Theme.base : Theme.text
    property real padding: 12
    property int fontSize: 11
    property alias hovered: mouse.containsMouse
    property bool hoverFeedback: true
    property bool wheelEnabled: false
    property string soundGroup: ""

    signal clicked
    signal secondaryClicked
    signal scrolled(real delta)

    function clickSound() {
        let item = root;
        while (item) {
            if (item.soundGroup) {
                UiSounds.play(item.soundGroup);
                return;
            }
            item = item.parent;
        }
    }

    onClicked: clickSound()
    implicitWidth: label.implicitWidth + padding * 2
    implicitHeight: 30
    radius: 5
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.42
    border.width: activeFocus ? 1 : 0
    border.color: Theme.text
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    color: selected ? Theme.text : mouse.pressed ? Theme.line : "transparent"
    scale: mouse.pressed ? 0.97 : 1
    Controls.ToolTip.visible: false
    Controls.ToolTip.delay: 550
    Controls.ToolTip.text: hint
    Accessible.role: Accessible.Button
    Accessible.name: hint || text
    Accessible.onPressAction: clicked()

    G2Surface {
        objectName: "key-hover-feedback"
        anchors.fill: parent
        radius: root.radius
        smoothing: root.smoothing
        color: root.color.r > 0.5 ? "#111111" : "#ffffff"
        opacity: mouse.pressed ? 0.16 : mouse.containsMouse && root.hoverFeedback ? 0.09 : 0

        Behavior on opacity {
            enabled: root.hoverFeedback
            NumberAnimation {
                duration: Theme.reducedMotion ? 0 : Theme.fast
            }
        }
    }

    Label {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.ink
        font.pixelSize: root.fontSize
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            return event.button === Qt.LeftButton ? root.clicked() : root.secondaryClicked();
        }
        onWheel: event => {
            if (!root.wheelEnabled) {
                event.accepted = false;
                return;
            }
            return root.scrolled(event.angleDelta.y);
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.reducedMotion ? 0 : Theme.fast
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : Theme.fast
            easing.type: Easing.OutCubic
        }
    }
}
