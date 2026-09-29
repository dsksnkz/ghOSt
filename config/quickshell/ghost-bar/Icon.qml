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
        const line = (x1, y1, x2, y2) => { c.beginPath(); c.moveTo(x1, y1); c.lineTo(x2, y2); c.stroke(); };
        const circle = (x, y, r) => { c.beginPath(); c.arc(x, y, r, 0, Math.PI * 2); c.stroke(); };
        switch (icon.name) {
        case "ghost":
            c.beginPath(); c.arc(cx, cy + 1, w * .29, Math.PI, Math.PI * 2); c.lineTo(cx + w * .29, h * .82); c.lineTo(cx + w * .14, h * .70); c.lineTo(cx, h * .82); c.lineTo(cx - w * .14, h * .70); c.lineTo(cx - w * .29, h * .82); c.closePath(); c.stroke();
            line(cx - w * .18, cy - h * .01, cx + w * .19, cy - h * .01); line(cx + w * .18, cy - h * .01, cx + w * .18, cy + h * .19); line(cx + w * .18, cy + h * .19, cx - w * .02, cy + h * .19);
            circle(cx - w * .12, cy - h * .11, 1.1); circle(cx + w * .12, cy - h * .11, 1.1); break;
        case "play": c.beginPath(); c.moveTo(w * .36, h * .25); c.lineTo(w * .70, cy); c.lineTo(w * .36, h * .75); c.closePath(); c.stroke(); break;
        case "pause": line(w * .39, h * .27, w * .39, h * .73); line(w * .61, h * .27, w * .61, h * .73); break;
        case "previous": line(w * .67, h * .25, w * .37, cy); line(w * .37, cy, w * .67, h * .75); line(w * .29, h * .25, w * .29, h * .75); break;
        case "next": line(w * .33, h * .25, w * .63, cy); line(w * .63, cy, w * .33, h * .75); line(w * .71, h * .25, w * .71, h * .75); break;
        case "wifi": c.beginPath(); c.arc(cx, h * .65, w * .39, Math.PI * 1.22, Math.PI * 1.78); c.stroke(); c.beginPath(); c.arc(cx, h * .65, w * .25, Math.PI * 1.24, Math.PI * 1.76); c.stroke(); c.beginPath(); c.arc(cx, h * .65, 1.5, 0, Math.PI * 2); c.fill(); break;
        case "bluetooth": line(cx, h * .16, cx, h * .84); line(cx, h * .16, w * .69, h * .36); line(w * .69, h * .36, w * .35, h * .66); line(w * .35, h * .34, w * .69, h * .64); line(w * .69, h * .64, cx, h * .84); break;
        case "volume": line(w * .22, h * .43, w * .38, h * .43); line(w * .38, h * .43, w * .55, h * .27); line(w * .38, h * .57, w * .55, h * .73); line(w * .38, h * .43, w * .38, h * .57); line(w * .55, h * .27, w * .55, h * .73); c.beginPath(); c.arc(w * .48, cy, w * .37, -Math.PI / 3, Math.PI / 3); c.stroke(); break;
        case "battery": c.strokeRect(w * .18, h * .27, w * .62, h * .46); c.fillRect(w * .80, h * .42, w * .10, h * .16); c.fillRect(w * .24, h * .33, w * .35, h * .34); break;
        case "network": circle(cx, cy, w * .13); line(cx, cy - w * .13, cx, h * .19); line(cx - w * .11, cy + w * .07, w * .22, h * .71); line(cx + w * .11, cy + w * .07, w * .78, h * .71); circle(cx, h * .17, 1.4); circle(w * .20, h * .75, 1.4); circle(w * .80, h * .75, 1.4); break;
        case "calendar": c.strokeRect(w * .19, h * .23, w * .62, h * .58); line(w * .19, h * .39, w * .81, h * .39); line(w * .35, h * .16, w * .35, h * .30); line(w * .65, h * .16, w * .65, h * .30); break;
        case "power": c.beginPath(); c.arc(cx, cy, w * .28, -Math.PI * .76, Math.PI * .76); c.stroke(); line(cx, h * .16, cx, h * .52); break;
        case "close": line(w * .27, h * .27, w * .73, h * .73); line(w * .73, h * .27, w * .27, h * .73); break;
        case "lock": c.strokeRect(w * .25, h * .43, w * .50, h * .37); c.beginPath(); c.arc(cx, h * .43, w * .22, Math.PI, 0); c.stroke(); break;
        case "settings": circle(cx, cy, w * .22); circle(cx, cy, w * .08); for (let i = 0; i < 8; i++) { const a = i * Math.PI / 4; line(cx + Math.cos(a) * w * .28, cy + Math.sin(a) * w * .28, cx + Math.cos(a) * w * .40, cy + Math.sin(a) * w * .40); } break;
        case "cpu": c.strokeRect(w * .25, h * .25, w * .50, h * .50); c.strokeRect(w * .37, h * .37, w * .26, h * .26); for (let i = 0; i < 4; i++) { const p = w * (.30 + i * .13); line(p, h * .12, p, h * .25); line(p, h * .75, p, h * .88); line(w * .12, p, w * .25, p); line(w * .75, p, w * .88, p); } break;
        case "gpu": c.beginPath(); c.moveTo(w * .18, h * .30); c.lineTo(w * .68, h * .30); c.lineTo(w * .82, h * .44); c.lineTo(w * .82, h * .70); c.lineTo(w * .25, h * .70); c.closePath(); c.stroke(); circle(w * .48, h * .50, w * .12); line(w * .18, h * .78, w * .62, h * .78); break;
        default: circle(cx, cy, w * .10); break;
        }
    }
}
