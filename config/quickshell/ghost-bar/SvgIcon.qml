import QtQuick

// Standalone assets; no system icon theme or other rice is required.
Item {
    id: icon

    property string name: "settings"
    property bool black: false
    property int fillMode: Image.PreserveAspectFit
    readonly property int status: artwork.status

    implicitWidth: 24
    implicitHeight: 24
    // Screen pixels per layout pixel, from every scaled parent (rail plane,
    // menus, shell Scale). The SVG is rasterised at exactly that size:
    // shrinking a larger raster is what made thin icon strokes look blurry.
    property real pixelScale: 1
    // The raster is drawn at whole screen pixels in size and position; a
    // fractional size or a half-pixel offset softens every edge.
    readonly property real ratio: Screen.devicePixelRatio || 1
    readonly property int pixels: Math.max(1, Math.round(Math.min(width, height) * ratio * pixelScale))
    property point snap: Qt.point(0, 0)
    function measure() {
        if (width <= 0 || !visible)
            return;
        const start = mapToItem(null, 0, 0), end = mapToItem(null, width, 0);
        const scale = Math.abs(end.x - start.x) / width;
        if (scale > 0 && Math.abs(scale - pixelScale) > .01)
            pixelScale = scale;
        // Offset, in this item's units, that moves the raster's corner onto a pixel.
        const size = pixels / (ratio * pixelScale);
        const left = start.x + (width - size) / 2 * pixelScale, top = start.y + (height - size) / 2 * pixelScale;
        snap = Qt.point((Math.round(left * ratio) / ratio - left) / pixelScale,
                        (Math.round(top * ratio) / ratio - top) / pixelScale);
    }
    Component.onCompleted: Qt.callLater(measure)
    onWidthChanged: Qt.callLater(measure)
    onHeightChanged: Qt.callLater(measure)
    onXChanged: Qt.callLater(measure)
    onYChanged: Qt.callLater(measure)
    onVisibleChanged: Qt.callLater(measure)

    Image {
        id: artwork

        readonly property real size: icon.pixels / (icon.ratio * icon.pixelScale)
        x: (icon.width - size) / 2 + icon.snap.x
        y: (icon.height - size) / 2 + icon.snap.y
        width: size
        height: size
        // Version the cache key when replacing the pack during a live reload.
        source: "icons/" + (icon.black ? "black/" : "white/") + icon.name + ".svg?v=ghost-20261025"
        sourceSize.width: icon.pixels
        sourceSize.height: icon.pixels
        fillMode: icon.fillMode
        smooth: true
    }
}
