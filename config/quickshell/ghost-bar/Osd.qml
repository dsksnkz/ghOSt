import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: window

    property bool opened: false
    function sync() {
        opened = OsdState.opened && OsdState.screenName === window.screen.name;
    }
    Component.onCompleted: sync()
    onScreenChanged: sync()
    Connections {
        target: OsdState
        function onOpenedChanged() {
            window.sync();
        }
        function onScreenNameChanged() {
            window.sync();
        }
    }
    property real reveal: opened ? 1 : 0

    visible: opened || reveal > 0.001
    implicitWidth: 80
    implicitHeight: 310
    margins.top: Math.round((screen.height - implicitHeight) / 2)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        left: true
        top: true
    }

    G2Surface {
        id: card

        x: -30 + 44 * window.reveal
        y: 8
        width: 44
        height: 294
        radius: 15
        smoothing: 0.6
        color: "#151515"
        border.color: "#393939"
        border.width: 1
        scale: 0.4 + 0.6 * window.reveal
        opacity: window.reveal

        SvgIcon {
            x: 10
            y: 16
            width: 24
            height: 24
            name: OsdState.kind === "brightness" ? "brightness" : Desk.muted ? "mute" : "volume"
        }

        Controls.Slider {
            id: slider

            x: 0
            y: 55
            width: 44
            height: 184
            orientation: Qt.Vertical
            from: 0
            to: 100
            stepSize: 1
            padding: 0
            value: OsdState.amount
            enabled: OsdState.available
            touchDragThreshold: 0
            Accessible.name: OsdState.kind
            onMoved: OsdState.move(value)
            onPressedChanged: OsdState.interacting = pressed

            background: G2Surface {
                x: 14
                y: 0
                width: 16
                height: slider.height
                radius: 9
                color: "#2c2c2c"

                G2Surface {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * slider.position
                    radius: 9
                    color: "#c6c6c6"
                }
            }

            // The filled track is the indicator; no floating horizontal cap.
            // Keep an empty handle item so Qt retains normal touch/drag input.
            handle: Item {
                width: 0
                height: 0
            }
        }

        Label {
            x: 0
            y: 255
            width: 44
            horizontalAlignment: Text.AlignHCenter
            text: OsdState.available ? Math.round(OsdState.amount) + "%" : "—"
            font.pixelSize: 14
        }
    }

    mask: Region {
        item: card
    }

    Behavior on reveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : 280
            easing.type: Easing.OutCubic
        }
    }
}
