import QtQuick

Item {
    id: root

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property color background: "#393939"

    implicitHeight: label.implicitHeight
    clip: true
    Accessible.role: Accessible.StaticText
    Accessible.name: text

    Label {
        id: label

        width: parent.width
        height: parent.height
        wrapMode: Text.NoWrap
        elide: Text.ElideNone
    }

    G2Surface {
        visible: label.implicitWidth > root.width
        anchors.right: parent.right
        // Keep the same edge treatment without erasing short/narrow labels.
        width: Math.min(28, root.width / 4)
        height: parent.height

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.rgba(root.background.r, root.background.g, root.background.b, 0)
            }

            GradientStop {
                position: 1
                color: root.background
            }
        }
    }
}
