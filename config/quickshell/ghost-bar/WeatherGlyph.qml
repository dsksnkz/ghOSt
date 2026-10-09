import QtQuick

Item {
    id: weather

    property string condition: "unknown"
    property bool active: false
    property bool reducedMotion: false
    property real rainPhase: 0
    readonly property bool moving: active && visible && !reducedMotion
    readonly property bool wet: condition === "rain" || condition === "storm"
    readonly property var motionState: ({
            "rain": rainPhase,
            "lightning": bolt.opacity,
            "moving": moving
        })

    implicitWidth: 108
    implicitHeight: 112

    // Cached geometry: lightning animates opacity, rain animates transforms.
    SvgIcon {
        width: 108
        height: 90
        name: "cloud"
        visible: weather.wet || weather.condition === "cloud"
    }

    SvgIcon {
        id: bolt

        x: 31
        y: 57
        width: 51
        height: 55
        name: "lightning"
        visible: weather.condition === "storm"
        opacity: 0.6

        SequentialAnimation on opacity {
            running: weather.moving && weather.condition === "storm"
            loops: Animation.Infinite

            PauseAnimation {
                duration: 3600
            }

            NumberAnimation {
                to: 1
                duration: 130
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                to: 0.6
                duration: 550
                easing.type: Easing.InOutSine
            }
        }
    }

    Repeater {
        model: weather.condition === "rain" ? 6 : 0

        G2Surface {
            required property int index
            readonly property real travel: (weather.rainPhase + index * 0.167) % 1

            x: 25 + index * 11 - travel * 5
            y: 77 + travel * 27
            width: 1.8
            height: 7
            radius: 0.9
            rotation: 18
            color: Theme.text
            opacity: weather.reducedMotion ? 0.7 : Math.sin(travel * Math.PI) * 0.85
        }
    }

    SvgIcon {
        anchors.centerIn: parent
        width: 94
        height: 94
        name: weather.condition === "clear" ? "brightness" : "snow"
        visible: weather.condition === "clear" || weather.condition === "snow"

        SequentialAnimation on rotation {
            running: weather.moving && weather.condition === "snow"
            loops: Animation.Infinite

            NumberAnimation {
                to: 8
                duration: 2400
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: -8
                duration: 2400
                easing.type: Easing.InOutSine
            }
        }
    }

    Label {
        anchors.centerIn: parent
        text: "—"
        visible: weather.condition === "unknown"
        font.pixelSize: 40
        color: Theme.muted
    }

    NumberAnimation on rainPhase {
        from: 0
        to: 1
        duration: 1100
        loops: Animation.Infinite
        running: weather.moving && weather.condition === "rain"
    }
}
