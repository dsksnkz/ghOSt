import QtQuick

Item {
    id: meter
    property string title: "CPU"
    property var value: null
    property real maximum: 100
    property string unit: "%"
    property bool active: false
    property bool reducedMotion: false
    property real phase: 0
    readonly property bool available: typeof value === "number" && isFinite(value)
    readonly property real level: available && maximum > 0 ? Math.max(0, Math.min(1, value / maximum)) : 0
    property real displayedLevel: level
    // Invert the diamond's cross-sectional area, so 20% fills 20% of its area.
    readonly property real fillHeight: displayedLevel <= .5 ? Math.sqrt(displayedLevel / 2) : 1 - Math.sqrt((1-displayedLevel) / 2)
    signal clicked()
    width: 188; height: 188
    FontLoader { id: instrumentFace; source: "fonts/TurretRoad-Bold.ttf" }
    activeFocusOnTab: true
    scale: hover.hovered || activeFocus ? 1.045 : 1
    Behavior on scale { NumberAnimation { duration: meter.reducedMotion ? 0 : 130; easing.type: Easing.OutCubic } }
    Behavior on displayedLevel { NumberAnimation { duration: meter.reducedMotion ? 0 : 400 } }
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: meter.clicked() }
    Accessible.role: Accessible.Button
    Accessible.name: title + ": " + (available ? Math.round(value) + unit : "Unavailable")
    Timer { running: meter.active && meter.visible && meter.available && !meter.reducedMotion; repeat: true; interval: 16; onTriggered: { meter.phase = (meter.phase + .032) % (Math.PI*2); liquid.requestPaint(); } }
    onDisplayedLevelChanged: liquid.requestPaint()
    onAvailableChanged: liquid.requestPaint()
    Canvas {
        id: liquid
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"), w = width, h = height, mid = w/2, r = 16;
            c.reset(); c.clearRect(0, 0, w, h);
            c.beginPath();
            c.moveTo(mid-r, r); c.quadraticCurveTo(mid, 0, mid+r, r);
            c.lineTo(w-r, h/2-r); c.quadraticCurveTo(w, h/2, w-r, h/2+r);
            c.lineTo(mid+r, h-r); c.quadraticCurveTo(mid, h, mid-r, h-r);
            c.lineTo(r, h/2+r); c.quadraticCurveTo(0, h/2, r, h/2-r); c.closePath();
            c.fillStyle = "#303030"; c.fill();
            if (meter.activeFocus) { c.strokeStyle = "#efefef"; c.lineWidth = 2; c.stroke(); }
            c.save(); c.clip();
            if (meter.available && meter.displayedLevel > 0) {
                const waterY = (h-8) - (h-16) * meter.fillHeight;
                for (let wave = 0; wave < 2; wave++) {
                    c.beginPath(); c.moveTo(0, h);
                    for (let x = 0; x <= w; x += 2) {
                        const amplitude = meter.displayedLevel >= .999 ? 0 : 5;
                        c.lineTo(x, waterY + Math.sin(x/w * 6.28 + meter.phase + wave*1.5) * amplitude);
                    }
                    c.lineTo(w,h); c.closePath(); c.fillStyle = wave ? "#d8d8d8" : "#9c9c9c"; c.fill();
                }
            }
            c.restore();
        }
        Connections { target: meter; function onActiveFocusChanged() { liquid.requestPaint(); } }
    }
    Label { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height*.40; text: meter.title; font.family: instrumentFace.status === FontLoader.Ready ? instrumentFace.name : Theme.font; font.pixelSize: 23; color: meter.displayedLevel > .6 ? "#141414" : "#f4f4f4" }
    Label { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height*.64; text: meter.available ? Math.round(meter.value).toString().padStart(2,"0") + meter.unit : "—"; font.family: instrumentFace.status === FontLoader.Ready ? instrumentFace.name : Theme.font; font.pixelSize: meter.unit === "MHz" ? 19 : 25; color: meter.displayedLevel > .29 ? "#141414" : "#f4f4f4" }
}
