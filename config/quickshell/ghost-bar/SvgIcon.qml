import QtQuick

// Standalone assets; no system icon theme or other rice is required.
Item {
    id: icon

    property string name: "settings"
    property bool black: false
    readonly property int status: artwork.status

    implicitWidth: 24
    implicitHeight: 24

    Image {
        id: artwork

        anchors.fill: parent
        source: "icons/" + (icon.black ? "black/" : "white/") + icon.name + ".svg"
        sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
        sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
