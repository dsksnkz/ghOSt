import QtQuick

Row {
    id: root

    property real value: 0
    property int count: 12
    property color ink: Theme.cream
    property int segmentWidth: 3

    spacing: 3

    Repeater {
        model: root.count

        G2Surface {
            required property int index

            width: root.segmentWidth
            height: 10
            radius: 0.5
            color: index < Math.round(root.value * root.count) ? root.ink : Theme.line

            Behavior on color {
                ColorAnimation {
                    duration: Theme.fast
                }
            }
        }
    }
}
