import "Corners.js" as Corners
import "WaveGeometry.js" as Waves
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
    property real titleY: 54
    property real valueY: 84
    readonly property bool available: typeof value === "number" && isFinite(value)
    readonly property real level: available && maximum > 0 ? Math.max(0, Math.min(1, value / maximum)) : 0
    property real displayedLevel: level
    // Invert the diamond's cross-sectional area, so 20% fills 20% of its area.
    readonly property real fillHeight: displayedLevel <= 0.5 ? Math.sqrt(displayedLevel / 2) : 1 - Math.sqrt((1 - displayedLevel) / 2)
    readonly property real waterLine: (height - 8) - (height - 16) * fillHeight
    readonly property var diamondPath: Corners.geometry(87, 87, 15, 0).commands
    readonly property var wavePoints: Waves.samples(width, 2)
    // Animate uniforms on accelerated backends, not three raster uploads/frame.
    // Keep the same Canvas path as a software/error fallback and static mask.
    readonly property bool useGpu: GraphicsInfo.api !== GraphicsInfo.Software && GraphicsInfo.api !== GraphicsInfo.Unknown && gpuLiquid.status !== ShaderEffect.Error
    function renderingStatus() {
        return {
            backend: useGpu ? "gpu" : "canvas",
            shaderStatus: gpuLiquid.status,
            shaderLog: gpuLiquid.log,
            moving: active && visible && available && !reducedMotion,
            phase: phase
        };
    }

    signal clicked

    width: 123
    height: 123
    activeFocusOnTab: true
    scale: tap.pressed ? 0.97 : 1
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Accessible.role: Accessible.Button
    Accessible.name: title + ": " + (available ? Math.round(value) + unit : "Unavailable")
    onDisplayedLevelChanged: if (!useGpu) liquid.requestPaint()
    onAvailableChanged: if (!useGpu) liquid.requestPaint()
    onUseGpuChanged: liquid.requestPaint()

    FontLoader {
        id: instrumentFace

        source: "fonts/TurretRoad-Bold.ttf"
    }

    FontLoader {
        id: valueFace

        source: "fonts/TurretRoad-Medium.ttf"
    }

    HoverHandler {
        id: hover

        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: liquid.requestPaint()
    }

    TapHandler {
        id: tap

        onTapped: meter.clicked()
    }

    Timer {
        running: meter.active && meter.visible && meter.available && !meter.reducedMotion
        repeat: true
        interval: 16
        onTriggered: {
            meter.phase = (meter.phase + 0.032) % (Math.PI * 2);
            if (!meter.useGpu)
                liquid.requestPaint();
        }
    }

    Canvas {
        id: liquid

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"), w = width, h = height, half = 87 / 2;
            c.reset();
            c.clearRect(0, 0, w, h);
            c.save();
            c.translate(w / 2, h / 2);
            c.rotate(Math.PI / 4);
            c.translate(-half, -half);
            Corners.traceCommands(c, meter.diamondPath);
            c.restore();
            c.fillStyle = hover.hovered ? "#3b3b3b" : "#313131";
            c.fill();
            if (meter.activeFocus) {
                c.strokeStyle = "#efefef";
                c.lineWidth = 2;
                c.stroke();
            }
            c.save();
            c.clip();
            if (!meter.useGpu && meter.available && meter.displayedLevel > 0) {
                const waterY = (h - 8) - (h - 16) * meter.fillHeight;
                const points = meter.wavePoints;
                const phase = meter.phase;
                const amplitude = meter.displayedLevel >= 0.999 ? 0 : 5;
                for (let wave = 0; wave < 2; wave++) {
                    Waves.trace(c, points, phase + wave * 1.5, waterY, amplitude, w, h);
                    c.fillStyle = wave ? "#f1f1f1" : "#b8b8b8";
                    c.fill();
                }
            }
            c.restore();
        }

        Connections {
            function onActiveFocusChanged() {
                liquid.requestPaint();
            }

            target: meter
        }
    }

    ShaderEffectSource {
        id: silhouette
        sourceItem: liquid
        hideSource: meter.useGpu
        live: true
        visible: false
    }

    ShaderEffect {
        id: gpuLiquid
        anchors.fill: parent
        visible: meter.useGpu
        fragmentShader: "shaders/liquid.frag.qsb"
        property var source: silhouette
        property size meterSize: Qt.size(width, height)
        property real wavePhase: meter.phase
        property real waterLine: meter.waterLine
        property real waveAmplitude: meter.displayedLevel >= 0.999 ? 0 : 5
        property real fillEnabled: meter.available && meter.displayedLevel > 0 ? 1 : 0
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        y: meter.titleY
        text: meter.title
        font.family: instrumentFace.name
        font.weight: Font.Bold
        font.pixelSize: 15
        color: meter.available && meter.titleY + 8 > meter.waterLine ? "#181818" : "#ffffff"
        // Only while a real wave crosses the glyphs: keep the reading legible.
        style: meter.available && meter.waterLine > y - 6 && meter.waterLine < y + height + 6 ? Text.Outline : Text.Normal
        styleColor: meter.titleY + 8 > meter.waterLine ? "#ffffff" : "#181818"
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        y: meter.valueY
        text: meter.available ? Math.round(meter.value).toString().padStart(2, "0") + meter.unit : "—"
        font.family: valueFace.name
        font.weight: Font.Medium
        font.pixelSize: meter.unit === "MHz" ? 12 : 15
        color: meter.available && meter.valueY + 8 > meter.waterLine ? "#181818" : "#ffffff"
        style: meter.available && meter.waterLine > y - 6 && meter.waterLine < y + height + 6 ? Text.Outline : Text.Normal
        styleColor: meter.valueY + 8 > meter.waterLine ? "#ffffff" : "#181818"
    }

    Behavior on scale {
        NumberAnimation {
            duration: meter.reducedMotion ? 0 : 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on displayedLevel {
        NumberAnimation {
            duration: meter.reducedMotion ? 0 : 400
        }
    }
}
