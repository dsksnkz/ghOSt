import QtQuick

G2Surface {
    radius: Theme.outerRadius
    color: Theme.base
    border.color: "#474747"
    border.width: 1
    gradient: Gradient {
        GradientStop { position: 0; color: "#161616" }
        GradientStop { position: 1; color: "#1c1c1c" }
    }
}
