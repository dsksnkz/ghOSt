import QtQuick

Canvas {
    id: icon

    property string name: "dot"
    property color ink: Theme.text
    property real stroke: 1.35

    implicitWidth: 18
    implicitHeight: 18
    antialiasing: true
    onNameChanged: requestPaint()
    onInkChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.clearRect(0, 0, width, height);
        c.strokeStyle = icon.ink;
        c.fillStyle = icon.ink;
        c.lineWidth = icon.stroke;
        c.lineCap = "round";
        c.lineJoin = "round";
        const w = width, h = height, cx = w / 2, cy = h / 2;
        const line = (x1, y1, x2, y2) => {
            c.beginPath();
            c.moveTo(x1, y1);
            c.lineTo(x2, y2);
            c.stroke();
        };
        const circle = (x, y, r) => {
            c.beginPath();
            c.arc(x, y, r, 0, Math.PI * 2);
            c.stroke();
        };
        switch (icon.name) {
        case "search":
            circle(w * 0.43, h * 0.43, w * 0.24);
            line(w * 0.61, h * 0.61, w * 0.82, h * 0.82);
            break;
        case "app":
            for (let x of [0.2, 0.55])
                for (let y of [0.2, 0.55])
                    c.strokeRect(w * x, h * y, w * 0.25, h * 0.25);
            break;
        case "terminal":
            c.strokeRect(w * 0.12, h * 0.2, w * 0.76, h * 0.6);
            line(w * 0.25, h * 0.35, w * 0.4, h * 0.5);
            line(w * 0.4, h * 0.5, w * 0.25, h * 0.65);
            line(w * 0.53, h * 0.65, w * 0.72, h * 0.65);
            break;
        case "browser":
            circle(cx, cy, w * 0.35);
            c.beginPath();
            c.ellipse(w * 0.35, h * 0.15, w * 0.3, h * 0.7);
            c.stroke();
            line(w * 0.15, cy, w * 0.85, cy);
            break;
        case "folder":
            c.beginPath();
            c.moveTo(w * 0.14, h * 0.28);
            c.lineTo(w * 0.4, h * 0.28);
            c.lineTo(w * 0.5, h * 0.4);
            c.lineTo(w * 0.86, h * 0.4);
            c.lineTo(w * 0.86, h * 0.76);
            c.lineTo(w * 0.14, h * 0.76);
            c.closePath();
            c.stroke();
            break;
        case "pin":
            line(w * 0.35, h * 0.2, w * 0.65, h * 0.2);
            line(w * 0.4, h * 0.2, w * 0.4, h * 0.43);
            line(w * 0.6, h * 0.2, w * 0.6, h * 0.43);
            c.beginPath();
            c.moveTo(w * 0.4, h * 0.43);
            c.lineTo(w * 0.27, h * 0.6);
            c.lineTo(w * 0.73, h * 0.6);
            c.lineTo(w * 0.6, h * 0.43);
            c.stroke();
            line(cx, h * 0.6, cx, h * 0.85);
            break;
        case "ghost":
            c.beginPath();
            c.arc(cx, cy + 1, w * 0.29, Math.PI, Math.PI * 2);
            c.lineTo(cx + w * 0.29, h * 0.82);
            c.lineTo(cx + w * 0.14, h * 0.7);
            c.lineTo(cx, h * 0.82);
            c.lineTo(cx - w * 0.14, h * 0.7);
            c.lineTo(cx - w * 0.29, h * 0.82);
            c.closePath();
            c.stroke();
            line(cx - w * 0.18, cy - h * 0.01, cx + w * 0.19, cy - h * 0.01);
            line(cx + w * 0.18, cy - h * 0.01, cx + w * 0.18, cy + h * 0.19);
            line(cx + w * 0.18, cy + h * 0.19, cx - w * 0.02, cy + h * 0.19);
            circle(cx - w * 0.12, cy - h * 0.11, 1.1);
            circle(cx + w * 0.12, cy - h * 0.11, 1.1);
            break;
        case "play":
            c.beginPath();
            c.moveTo(w * 0.36, h * 0.25);
            c.lineTo(w * 0.7, cy);
            c.lineTo(w * 0.36, h * 0.75);
            c.closePath();
            c.stroke();
            break;
        case "pause":
            line(w * 0.39, h * 0.27, w * 0.39, h * 0.73);
            line(w * 0.61, h * 0.27, w * 0.61, h * 0.73);
            break;
        case "previous":
            line(w * 0.67, h * 0.25, w * 0.37, cy);
            line(w * 0.37, cy, w * 0.67, h * 0.75);
            line(w * 0.29, h * 0.25, w * 0.29, h * 0.75);
            break;
        case "next":
            line(w * 0.33, h * 0.25, w * 0.63, cy);
            line(w * 0.63, cy, w * 0.33, h * 0.75);
            line(w * 0.71, h * 0.25, w * 0.71, h * 0.75);
            break;
        case "wifi":
            c.beginPath();
            c.arc(cx, h * 0.65, w * 0.39, Math.PI * 1.22, Math.PI * 1.78);
            c.stroke();
            c.beginPath();
            c.arc(cx, h * 0.65, w * 0.25, Math.PI * 1.24, Math.PI * 1.76);
            c.stroke();
            c.beginPath();
            c.arc(cx, h * 0.65, 1.5, 0, Math.PI * 2);
            c.fill();
            break;
        case "bluetooth":
            line(cx, h * 0.16, cx, h * 0.84);
            line(cx, h * 0.16, w * 0.69, h * 0.36);
            line(w * 0.69, h * 0.36, w * 0.35, h * 0.66);
            line(w * 0.35, h * 0.34, w * 0.69, h * 0.64);
            line(w * 0.69, h * 0.64, cx, h * 0.84);
            break;
        case "volume":
            line(w * 0.22, h * 0.43, w * 0.38, h * 0.43);
            line(w * 0.38, h * 0.43, w * 0.55, h * 0.27);
            line(w * 0.38, h * 0.57, w * 0.55, h * 0.73);
            line(w * 0.38, h * 0.43, w * 0.38, h * 0.57);
            line(w * 0.55, h * 0.27, w * 0.55, h * 0.73);
            c.beginPath();
            c.arc(w * 0.48, cy, w * 0.37, -Math.PI / 3, Math.PI / 3);
            c.stroke();
            break;
        case "battery":
            c.strokeRect(w * 0.18, h * 0.27, w * 0.62, h * 0.46);
            c.fillRect(w * 0.8, h * 0.42, w * 0.1, h * 0.16);
            c.fillRect(w * 0.24, h * 0.33, w * 0.35, h * 0.34);
            break;
        case "network":
            circle(cx, cy, w * 0.13);
            line(cx, cy - w * 0.13, cx, h * 0.19);
            line(cx - w * 0.11, cy + w * 0.07, w * 0.22, h * 0.71);
            line(cx + w * 0.11, cy + w * 0.07, w * 0.78, h * 0.71);
            circle(cx, h * 0.17, 1.4);
            circle(w * 0.2, h * 0.75, 1.4);
            circle(w * 0.8, h * 0.75, 1.4);
            break;
        case "calendar":
            c.strokeRect(w * 0.19, h * 0.23, w * 0.62, h * 0.58);
            line(w * 0.19, h * 0.39, w * 0.81, h * 0.39);
            line(w * 0.35, h * 0.16, w * 0.35, h * 0.3);
            line(w * 0.65, h * 0.16, w * 0.65, h * 0.3);
            break;
        case "power":
            c.beginPath();
            c.arc(cx, cy, w * 0.28, -Math.PI * 0.25, Math.PI * 1.25);
            c.stroke();
            line(cx, h * 0.16, cx, h * 0.52);
            break;
        case "close":
            line(w * 0.27, h * 0.27, w * 0.73, h * 0.73);
            line(w * 0.73, h * 0.27, w * 0.27, h * 0.73);
            break;
        case "lock":
            c.strokeRect(w * 0.25, h * 0.43, w * 0.5, h * 0.37);
            c.beginPath();
            c.arc(cx, h * 0.43, w * 0.22, Math.PI, 0);
            c.stroke();
            break;
        case "settings":
            circle(cx, cy, w * 0.22);
            circle(cx, cy, w * 0.08);
            for (let i = 0; i < 8; i++) {
                const a = i * Math.PI / 4;
                line(cx + Math.cos(a) * w * 0.28, cy + Math.sin(a) * w * 0.28, cx + Math.cos(a) * w * 0.4, cy + Math.sin(a) * w * 0.4);
            }
            break;
        case "cpu":
            c.strokeRect(w * 0.25, h * 0.25, w * 0.5, h * 0.5);
            c.strokeRect(w * 0.37, h * 0.37, w * 0.26, h * 0.26);
            for (let i = 0; i < 4; i++) {
                const p = w * (0.3 + i * 0.13);
                line(p, h * 0.12, p, h * 0.25);
                line(p, h * 0.75, p, h * 0.88);
                line(w * 0.12, p, w * 0.25, p);
                line(w * 0.75, p, w * 0.88, p);
            }
            break;
        case "gpu":
            c.beginPath();
            c.moveTo(w * 0.18, h * 0.3);
            c.lineTo(w * 0.68, h * 0.3);
            c.lineTo(w * 0.82, h * 0.44);
            c.lineTo(w * 0.82, h * 0.7);
            c.lineTo(w * 0.25, h * 0.7);
            c.closePath();
            c.stroke();
            circle(w * 0.48, h * 0.5, w * 0.12);
            line(w * 0.18, h * 0.78, w * 0.62, h * 0.78);
            break;
        default:
            circle(cx, cy, w * 0.1);
            break;
        }
    }
}
