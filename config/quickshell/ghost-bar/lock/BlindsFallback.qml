import QtQuick

Item {
    id: view
    property real opening: 0
    property real cursorTilt: 0
    readonly property int count: Math.max(1, Math.ceil((height - 52) / 36))
    readonly property real pitch: (height - 52) / count
    readonly property real frameOpacity: 1 - Math.max(0, (opening - 0.6) / 0.4)
    Repeater {
        model: view.count
        Rectangle {
            id: blade
            required property int index
            readonly property real turn: Math.max(0, Math.min(1, (view.opening - index / view.count * 0.15) / 0.85))
            x: 18; y: 28 + index * view.pitch
            width: view.width - 36; height: view.pitch + 4
            radius: 6
            opacity: 1 - Math.max(0, (turn - 0.92) / 0.08)
            gradient: Gradient {
                GradientStop { position: 0; color: "#111111" }
                GradientStop { position: 0.035; color: "#686868" }
                GradientStop { position: 0.14; color: "#595959" }
                GradientStop { position: 0.4; color: "#444444" }
                GradientStop { position: 0.68; color: "#393939" }
                GradientStop { position: 0.91; color: "#262626" }
                GradientStop { position: 0.98; color: "#505050" }
                GradientStop { position: 1; color: "#141414" }
            }
            Rectangle { x: 5; y: 2; width: parent.width - 10; height: 1; color: "#777777"; opacity: 0.3 }
            Canvas {
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    let seed = 431 + blade.index * 97;
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = "rgba(255,255,255,0.025)";
                    for (let i = 0; i < 100; i++) {
                        seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
                        const y = 5 + seed / 4294967296 * (height - 10);
                        const x = (i * 83) % Math.max(1, width - 70);
                        ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + 70, y); ctx.stroke();
                    }
                }
            }
            transform: Rotation {
                origin.x: blade.width / 2; origin.y: blade.height / 2
                axis { x: 1; y: 0; z: 0 }
                angle: 82 * blade.turn + view.cursorTilt * (1 - blade.turn)
            }
        }
    }
    Repeater {
        model: 4
        Rectangle {
            required property int index
            x: (index < 2 ? view.width * 0.2 : view.width * 0.8) + (index % 2 ? 2 : -2)
            y: 18; width: 1.5; height: view.height - 30
            color: index % 2 ? "#555555" : "#1d1d1d"
            opacity: view.frameOpacity * 0.85
        }
    }
    Repeater {
        model: 2
        Rectangle {
            required property int index
            x: index ? 15 : 12; y: index ? view.height - 24 : 0
            width: view.width - (index ? 30 : 24); height: index ? 24 : 28
            radius: 4; opacity: view.frameOpacity
            gradient: Gradient {
                GradientStop { position: 0; color: "#767676" }
                GradientStop { position: 0.13; color: "#515151" }
                GradientStop { position: 0.75; color: "#2a2a2a" }
                GradientStop { position: 1; color: "#121212" }
            }
        }
    }
}
