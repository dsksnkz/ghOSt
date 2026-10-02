import QtQuick
import Quickshell.Hyprland

Item {
    id: wheel
    property var monitor
    readonly property int current: Math.max(1, monitor?.activeWorkspace?.id ?? Desk.activeWorkspace)
    width: 118
    height: 34

    Row {
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: [-1, 0, 1]
            Key {
                required property int modelData
                readonly property int workspace: wheel.current + modelData
                readonly property bool central: modelData === 0
                width: central ? 40 : 35
                height: 32
                padding: 0
                enabled: workspace > 0
                color: "transparent"
                ink: central ? Theme.text : Theme.muted
                text: workspace > 0 ? String(workspace).padStart(2, "0") : ""
                hint: "Workspace " + workspace
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspace + " })")
                onScrolled: delta => Hyprland.dispatch("hl.dsp.focus({ workspace = '" + (delta > 0 ? "e-1" : "e+1") + "' })")

                Canvas {
                    visible: parent.central
                    x: (parent.width - width) / 2
                    y: 28
                    width: 12
                    height: 5
                    onPaint: {
                        const c = getContext("2d"); c.reset();
                        c.beginPath(); c.moveTo(0, 5); c.lineTo(6, 0); c.lineTo(12, 5);
                        c.closePath(); c.fillStyle = "#dddddd"; c.fill();
                    }
                }
            }
        }
    }
}
