import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// One workspace drawn at full resolution, then mipmapped so it stays sharp when
// shown small. Window captures are single frames.
Item {
    id: preview
    required property var windows
    required property var monitor
    required property string wallpaper
    property real resolution: 1
    readonly property real logicalWidth: monitor?.width ?? 1920
    readonly property real cornerRadius: 26
    layer.enabled: true
    layer.mipmap: true
    layer.smooth: true
    layer.textureSize: Qt.size(width * resolution, height * resolution)

    ClippingRectangle {
        anchors.fill: parent
        radius: preview.cornerRadius
        color: "#0b0b0b"
        Image {
            anchors.fill: parent
            source: preview.wallpaper
            sourceSize.width: 1920
            fillMode: Image.PreserveAspectCrop
        }
        Item {
            width: preview.logicalWidth
            height: preview.monitor?.height ?? 1080
            scale: preview.width / preview.logicalWidth
            transformOrigin: Item.TopLeft
            Repeater {
                model: preview.windows.length
                Item {
                    required property int index
                    readonly property var details: preview.windows[index] ?? {}
                    x: (details.at?.[0] ?? 0) - (preview.monitor?.x ?? 0)
                    y: (details.at?.[1] ?? 0) - (preview.monitor?.y ?? 0)
                    width: details.size?.[0] ?? 0
                    height: details.size?.[1] ?? 0
                    // Most recently focused on top, always above the wallpaper.
                    z: 1000 - (details.focusHistoryID ?? 0)
                    ScreencopyView {
                        id: capture
                        anchors.fill: parent
                        captureSource: parent.details.source ?? null
                        live: false
                        paintCursor: false
                    }
                    // A capture can fail while its window is being mapped; ask again.
                    Timer {
                        property int attempts: 0
                        interval: 120
                        repeat: true
                        running: capture.captureSource !== null && !capture.hasContent && attempts < 4
                        onTriggered: {
                            attempts++;
                            capture.captureFrame();
                        }
                    }
                }
            }
        }
        Rectangle {
            width: parent.width
            height: Theme.railHeight
            color: "#191919"
            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(Desk.now, "HH:mm")
                font.family: Theme.font
                font.pixelSize: 20
                color: "#ffffff"
            }
        }
    }
}
