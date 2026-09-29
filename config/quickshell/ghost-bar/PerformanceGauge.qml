import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: gauge
    property bool active: false
    property string metric: "cpu"
    property real cpuLoad: 0
    property real gpuLoad: 0
    property real clockMHz: 0
    signal metricSelected(string value)
    implicitHeight: 166
    readonly property real level: metric === "gpu" ? gpuLoad / 100 : metric === "processor" ? Math.min(1, clockMHz / 5000) : cpuLoad / 100
    readonly property string metricName: metric === "gpu" ? "GPU LOAD" : metric === "processor" ? "PROCESSOR MHZ" : "CPU LOAD"
    readonly property string metricValue: metric === "processor" ? Math.round(clockMHz) + "" : Math.round(metric === "gpu" ? gpuLoad : cpuLoad) + "%"
    Timer { interval: 1000; repeat: true; running: gauge.active; triggeredOnStart: true; onTriggered: { sample.running = false; sample.running = true; } }
    Process {
        id: sample
        command: ["bash", "-lc", "awk '{print $1*10,0,0}' /proc/loadavg"]
        stdout: StdioCollector {
            id: output
            onStreamFinished: {
                const v = output.text.trim().split(/\s+/).map(Number);
                if (v.length >= 3 && v.every(n => Number.isFinite(n))) { gauge.cpuLoad = Math.max(0, Math.min(100, v[0])); gauge.gpuLoad = Math.max(0, Math.min(100, v[1])); gauge.clockMHz = Math.max(0, v[2]); }
            }
        }
    }
    Canvas {
        id: dial
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: metrics.left; rightMargin: 20 }
        onPaint: {
            const c = getContext("2d"); c.reset(); c.clearRect(0, 0, width, height);
            const cx = width / 2, cy = height / 2, radius = Math.min(width, height) * .37, ticks = 48, lit = Math.round(gauge.level * ticks);
            c.lineWidth = 1.15; c.lineCap = "butt";
            for (let i = 0; i < ticks; i++) { const a = -Math.PI * .75 + i * Math.PI * 1.5 / (ticks - 1); c.beginPath(); c.moveTo(cx + Math.cos(a) * (radius - 7), cy + Math.sin(a) * (radius - 7)); c.lineTo(cx + Math.cos(a) * radius, cy + Math.sin(a) * radius); c.strokeStyle = i < lit ? Theme.text : Theme.line; c.stroke(); }
            c.fillStyle = Theme.text; c.font = "600 21px JetBrains Mono"; c.textAlign = "center"; c.fillText(gauge.metricValue, cx, cy + 3);
            c.fillStyle = Theme.muted; c.font = "9px JetBrains Mono"; c.fillText(gauge.metricName, cx, cy + 22);
        }
        Connections { target: gauge; function onLevelChanged() { dial.requestPaint(); } function onMetricChanged() { dial.requestPaint(); } function onCpuLoadChanged() { dial.requestPaint(); } function onGpuLoadChanged() { dial.requestPaint(); } function onClockMHzChanged() { dial.requestPaint(); } }
    }
    Column {
        id: metrics
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: 104; spacing: 8
        Label { text: "PERFORMANCE"; color: Theme.muted; font.pixelSize: 9; font.letterSpacing: 1 }
        Label { text: "RADIAL / LIVE"; color: Theme.faint; font.pixelSize: 8; font.letterSpacing: 1 }
        Item { width: 1; height: 5 }
        Key { width: parent.width; height: 30; text: "CPU"; selected: gauge.metric === "cpu"; onClicked: gauge.metricSelected("cpu") }
        Key { width: parent.width; height: 30; text: "GPU"; selected: gauge.metric === "gpu"; onClicked: gauge.metricSelected("gpu") }
        Key { width: parent.width; height: 30; text: "MHZ"; selected: gauge.metric === "processor"; onClicked: gauge.metricSelected("processor") }
    }
}
