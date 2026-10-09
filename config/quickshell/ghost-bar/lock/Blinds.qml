import QtQuick

Item {
    id: blinds
    property real drop: 1
    property real opening: 0
    readonly property int count: Math.max(1, Math.ceil(height / 54))
    readonly property real slatHeight: height / count
    y: (drop - 1) * height

    Repeater {
        model: blinds.count
        Rectangle {
            required property int index
            readonly property real turn: Math.max(0, Math.min(1, (blinds.opening - index / blinds.count * 0.15) / 0.85))
            x: -2
            y: index * blinds.slatHeight
            width: blinds.width + 4
            height: blinds.slatHeight + 1
            opacity: 1 - Math.max(0, (turn - 0.8) / 0.2)
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#454545"
                }
                GradientStop {
                    position: 0.12
                    color: "#393939"
                }
                GradientStop {
                    position: 0.7
                    color: "#292929"
                }
                GradientStop {
                    position: 1
                    color: "#151515"
                }
            }
            transform: Rotation {
                origin.x: width / 2
                origin.y: height / 2
                axis {
                    x: 1
                    y: 0
                    z: 0
                }
                angle: 90 * turn
            }
        }
    }
}
