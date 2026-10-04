import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: gauge

    property bool active: false
    property string metric: "cpu"
    property var reading: null
    property var maximum: null
    readonly property string metricName: metric === "gpu" ? "GPU UTILIZATION" : metric === "processor" ? "PROCESSOR CLOCK" : "CPU UTILIZATION"
    readonly property bool available: typeof reading === "number" && isFinite(reading)
    readonly property real level: available && maximum > 0 ? Math.max(0, Math.min(1, reading / maximum)) : 0
    property real displayedLevel: level

    signal metricSelected(string value)

    implicitHeight: 208
    onMetricChanged: {
        reading = null;
        maximum = null;
        if (active) {
            sample.running = false;
            restart.start();
        }
    }
    onActiveChanged: {
        reading = null;
        if (active) {
            restart.start();
        } else {
            restart.stop();
            sample.running = false;
        }
    }
    Component.onCompleted: {
        if (active) {
            restart.start();
        }
    }

    Timer {
        id: restart

        interval: 20
        onTriggered: {
            if (gauge.active) {
                sample.running = true;
            }
        }
    }

    Process {
        id: sample

        command: ["python3", Quickshell.shellPath("metrics.py"), gauge.metric]
        onExited: {
            gauge.reading = null;
            stale.stop();
        }

        stdout: SplitParser {
            onRead: data => {
                try {
                    const record = JSON.parse(data);
                    if (record.metric === gauge.metric) {
                        gauge.reading = record.value;
                        gauge.maximum = record.maximum;
                        stale.restart();
                    }
                } catch (error) {
                    gauge.reading = null;
                }
            }
        }
    }

    Timer {
        id: stale

        interval: 3500
        onTriggered: gauge.reading = null
    }

    Item {
        id: dialFrame

        anchors {
            left: parent.left
            right: metrics.left
            rightMargin: 20
            top: parent.top
            bottom: parent.bottom
        }

        Canvas {
            id: dial

            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                c.clearRect(0, 0, width, height);
                const cx = width / 2, cy = height / 2, radius = Math.min(width, height) * 0.46, ticks = 60;
                const lit = Math.round(gauge.displayedLevel * ticks);
                c.lineWidth = 1.6;
                for (let i = 0; i < ticks; i++) {
                    const a = Math.PI * 0.75 + i * Math.PI * 1.5 / (ticks - 1);
                    const length = i % 5 === 0 ? 12 : 8;
                    c.beginPath();
                    c.moveTo(cx + Math.cos(a) * (radius - length), cy + Math.sin(a) * (radius - length));
                    c.lineTo(cx + Math.cos(a) * radius, cy + Math.sin(a) * radius);
                    c.strokeStyle = gauge.available && i < lit ? Theme.text : Theme.line;
                    c.stroke();
                }
            }

            Connections {
                function onDisplayedLevelChanged() {
                    dial.requestPaint();
                }

                function onAvailableChanged() {
                    dial.requestPaint();
                }

                target: gauge
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 8

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.available ? Math.round(gauge.reading) + (gauge.metric === "processor" ? "" : "%") : "—"
                font.pixelSize: 32
                font.weight: Font.Medium
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.available ? gauge.metric === "processor" ? "MHz · AVERAGE" : "UTILIZATION" : "UNAVAILABLE"
                font.pixelSize: 8
                color: Theme.muted
                font.letterSpacing: 0.4
            }
        }
    }

    Column {
        id: metrics

        width: 100
        spacing: 8

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        Label {
            text: "PERFORMANCE"
            color: Theme.muted
            font.pixelSize: 9
            font.letterSpacing: 0.4
        }

        Item {
            height: 6
            width: 1
        }

        Repeater {
            model: [
                {
                    "key": "cpu",
                    "title": "CPU",
                    "icon": "cpu"
                },
                {
                    "key": "gpu",
                    "title": "GPU",
                    "icon": "gpu"
                },
                {
                    "key": "processor",
                    "title": "CLOCK",
                    "icon": "cpu"
                }
            ]

            Key {
                required property var modelData

                width: 100
                height: 34
                selected: gauge.metric === modelData.key
                hint: modelData.key === "processor" ? "Average processor frequency in MHz" : modelData.title + " utilization"
                onClicked: gauge.metricSelected(modelData.key)

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Icon {
                        width: 15
                        height: 15
                        name: modelData.icon
                        ink: gauge.metric === modelData.key ? Theme.base : Theme.text
                    }

                    Label {
                        text: modelData.title
                        font.pixelSize: 10
                        color: gauge.metric === modelData.key ? Theme.base : Theme.text
                    }
                }
            }
        }
    }

    Behavior on displayedLevel {
        NumberAnimation {
            duration: Theme.motion
            easing.type: Easing.OutCubic
        }
    }
}
