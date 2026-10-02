import QtQuick

Item {
    id: weather
    property string condition: "unknown"
    property bool active: false
    property bool reducedMotion: false
    property real rainPhase: 0
    readonly property bool moving: active && visible && !reducedMotion
    readonly property bool wet: condition === "rain" || condition === "storm"
    readonly property var motionState: ({rain:rainPhase,lightning:bolt.opacity,moving:moving})
    implicitWidth: 108
    implicitHeight: 112

    // Cached geometry: lightning animates opacity, rain animates transforms.
    Canvas {
        width:108; height:112
        visible: weather.wet || weather.condition === "cloud"
        onPaint: {
            const c=getContext("2d"); c.reset();
            c.strokeStyle="#f4f4f4"; c.lineWidth=2.5;
            c.lineCap="round"; c.lineJoin="round";
            c.beginPath(); c.moveTo(24,74);
            c.bezierCurveTo(-4,59,5,12,38,10);
            c.bezierCurveTo(58,9,72,21,76,39);
            c.bezierCurveTo(111,36,116,72,91,79); c.stroke();
        }
    }
    Canvas {
        id: bolt
        width:108; height:112
        visible: weather.condition === "storm"
        opacity: .6
        onPaint: {
            const c=getContext("2d"); c.reset();
            c.strokeStyle="#ffffff"; c.lineWidth=3;
            c.lineCap="round"; c.lineJoin="round";
            c.beginPath(); c.moveTo(60,58); c.lineTo(43,83);
            c.lineTo(68,83); c.lineTo(51,109); c.stroke();
        }
        SequentialAnimation on opacity {
            running: weather.moving && weather.condition === "storm"
            loops: Animation.Infinite
            PauseAnimation { duration: 3600 }
            NumberAnimation { to: 1; duration: 130; easing.type: Easing.OutQuad }
            NumberAnimation { to: .6; duration: 550; easing.type: Easing.InOutSine }
        }
    }
    NumberAnimation on rainPhase {
        from:0; to:1; duration:1100; loops:Animation.Infinite
        running: weather.moving && weather.condition === "rain"
    }
    Repeater {
        model: weather.condition === "rain" ? 6 : 0
        Rectangle {
            required property int index
            readonly property real travel: (weather.rainPhase + index*.167)%1
            x: 25 + index*11 - travel*5; y: 77 + travel*27
            width:1.8; height:7; radius:.9; rotation:18
            color:Theme.text
            opacity: weather.reducedMotion ? .7 : Math.sin(travel*Math.PI)*.85
        }
    }
    SvgIcon {
        anchors.centerIn:parent; width:94; height:94
        name: weather.condition === "clear" ? "brightness" : "snow"
        visible: weather.condition === "clear" || weather.condition === "snow"
        SequentialAnimation on rotation {
            running: weather.moving && weather.condition === "snow"
            loops: Animation.Infinite
            NumberAnimation { to:8; duration:2400; easing.type:Easing.InOutSine }
            NumberAnimation { to:-8; duration:2400; easing.type:Easing.InOutSine }
        }
    }
    Label { anchors.centerIn:parent; text:"—"; visible:weather.condition === "unknown"; font.pixelSize:40; color:Theme.muted }
}
