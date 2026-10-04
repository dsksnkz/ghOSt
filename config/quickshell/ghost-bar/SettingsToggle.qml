import QtQuick

Key {
    id: toggle

    property bool checked: false

    signal toggled(bool value)

    implicitWidth: 54
    implicitHeight: 20
    radius: 10
    color: "#555555"
    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked
    onClicked: toggled(!checked)

    G2Surface {
        x: toggle.checked ? 26 : 2
        y: 2
        width: 26
        height: 16
        radius: 8
        color: "#c2c2c2"

        Behavior on x {
            NumberAnimation {
                duration: Theme.reducedMotion ? 0 : 120
                easing.type: Easing.OutCubic
            }
        }
    }
}
