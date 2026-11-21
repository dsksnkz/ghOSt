import QtQuick

// Thin line glyphs the icon set lacks: "up" and "down" arrows, a "radio" signal mark,
// and the design's outlined "wifi", "bluetooth" rune and "phone" handset.
Canvas {
    id: glyph
    property string kind: "up"
    property color ink: "#666666"
    implicitWidth: 16
    implicitHeight: 16
    onKindChanged: requestPaint()
    onInkChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.strokeStyle = ink;
        c.fillStyle = ink;
        c.lineWidth = 1.4;
        c.lineCap = "round";
        c.lineJoin = "round";
        const w = width, h = height, cx = w / 2;
        if (kind === "up" || kind === "down") {
            const tip = kind === "up" ? 1 : h - 1, tail = kind === "up" ? h - 1 : 1;
            const wing = kind === "up" ? tip + w * .42 : tip - w * .42;
            c.beginPath();
            c.moveTo(cx, tail);
            c.lineTo(cx, tip);
            c.moveTo(cx - w * .42, wing);
            c.lineTo(cx, tip);
            c.lineTo(cx + w * .42, wing);
            c.stroke();
        } else if (kind === "wifi") {
            // Three arcs over a dot, opening upwards.
            const base = h - 1.5;
            c.beginPath();
            c.arc(cx, base - 1, 1.4, 0, Math.PI * 2);
            c.fill();
            for (const r of [h * .36, h * .64, h * .92]) {
                c.beginPath();
                c.arc(cx, base, r, Math.PI * 1.25, Math.PI * 1.75);
                c.stroke();
            }
        } else if (kind === "bluetooth") {
            c.lineWidth = 2.2;
            const left = w * .18, right = w * .82, top = 1, bottom = h - 1;
            c.beginPath();
            c.moveTo(left, h * .28);
            c.lineTo(right, h * .7);
            c.lineTo(cx, bottom);
            c.lineTo(cx, top);
            c.lineTo(right, h * .3);
            c.lineTo(left, h * .72);
            c.stroke();
        } else if (kind === "phone") {
            // Handset: earpiece at the top left, mouthpiece at the bottom right.
            c.beginPath();
            c.moveTo(w * .22, h * .06);
            c.lineTo(w * .36, h * .06);
            c.lineTo(w * .44, h * .3);
            c.lineTo(w * .32, h * .4);
            c.quadraticCurveTo(w * .42, h * .62, w * .6, h * .7);
            c.lineTo(w * .7, h * .58);
            c.lineTo(w * .94, h * .66);
            c.lineTo(w * .94, h * .8);
            c.quadraticCurveTo(w * .9, h * .96, w * .72, h * .94);
            c.quadraticCurveTo(w * .1, h * .8, w * .06, h * .22);
            c.quadraticCurveTo(w * .06, h * .06, w * .22, h * .06);
            c.stroke();
        } else {
            const cy = h / 2;
            c.beginPath();
            c.arc(cx, cy, 2, 0, Math.PI * 2);
            c.fill();
            for (const r of [w * .26, w * .44]) {
                c.beginPath();
                c.arc(cx, cy, r, Math.PI * .72, Math.PI * 1.28);
                c.stroke();
                c.beginPath();
                c.arc(cx, cy, r, -Math.PI * .28, Math.PI * .28);
                c.stroke();
            }
        }
    }
}
