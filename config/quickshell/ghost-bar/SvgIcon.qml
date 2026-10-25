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

    Image {
        id: artwork

        anchors.fill: parent
        // Version the cache key when replacing the pack during a live reload.
        source: "icons/" + (icon.black ? "black/" : "white/") + icon.name + ".svg?v=ghost-20261025"
        // Parent surfaces have fractional scales (rail .9, sidebar .7/1.15).
        // Cache a larger SVG raster rather than magnifying a tiny 12–18px texture.
        // This changes sampling resolution only, never the icon's layout size.
        sourceSize.width: Math.max(48, Math.ceil(width * Screen.devicePixelRatio * 2))
        sourceSize.height: Math.max(48, Math.ceil(height * Screen.devicePixelRatio * 2))
        fillMode: icon.fillMode
        smooth: true
        mipmap: true
    }
}
