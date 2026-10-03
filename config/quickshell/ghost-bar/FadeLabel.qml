import QtQuick

Item {
    id: root
    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property color background: "#393939"
    implicitHeight: label.implicitHeight
    clip: true
    Label { id:label; width:parent.width; height:parent.height; wrapMode:Text.NoWrap; elide:Text.ElideNone }
    G2Surface {
        visible:label.implicitWidth>root.width
        anchors.right:parent.right; width:28; height:parent.height
        gradient:Gradient {
            orientation:Gradient.Horizontal
            GradientStop { position:0; color:Qt.rgba(root.background.r,root.background.g,root.background.b,0) }
            GradientStop { position:1; color:root.background }
        }
    }
    Accessible.role:Accessible.StaticText
    Accessible.name:text
}
