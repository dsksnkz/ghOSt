import QtQuick

Rectangle {
    radius: 8
    color: Theme.base
    border.color: Theme.line
    border.width: 1
    gradient: Gradient {
        GradientStop { position: 0; color: "#202424" }
        GradientStop { position: 0.18; color: "#181b1b" }
        GradientStop { position: 1; color: "#121414" }
    }
    // One cached paint per size change. There is no animated noise or shader loop.
    Canvas {
        anchors.fill: parent
        anchors.margins: 2
        opacity: 0.19
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d");
            c.clearRect(0, 0, width, height);
            c.fillStyle = "#707775";
            for (let y = 2; y < height; y += 4)
                for (let x = (y % 8 ? 2 : 4); x < width; x += 4)
                    c.fillRect(x, y, 0.6, 0.6);
        }
    }
    Rectangle { x: 9; y: 1; width: parent.width - 18; height: 1; color: "#454b48"; opacity: 0.5 }
}
