import QtQuick
import QtQuick.Controls as Controls

Controls.Slider {
    id: slider

    property string label: ""

    from: 0
    to: 100
    stepSize: 1
    implicitWidth: 350
    implicitHeight: 32
    padding: 0
    Accessible.name: label
    onPressedChanged: if (pressed)
        UiSounds.play("settings")

    background: Item {
        y: 12
        width: slider.width
        height: 8

        G2Surface {
            anchors.fill: parent
            radius: 4
            color: "#414141"
        }

        G2Surface {
            width: parent.width * slider.visualPosition
            height: parent.height
            radius: 4
            color: slider.enabled ? "#d9d9d9" : "#676767"
        }
    }

    handle: G2Surface {
        x: slider.visualPosition * (slider.width - width)
        y: 7
        width: 18
        height: 18
        radius: 6
        color: slider.enabled ? slider.pressed ? "#ffffff" : "#d9d9d9" : "#676767"
        border.width: slider.activeFocus ? 1 : 0
        border.color: "#ffffff"
    }
}
