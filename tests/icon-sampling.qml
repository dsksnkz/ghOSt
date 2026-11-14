import QtQuick
import Quickshell

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 160
        implicitHeight: 100
        Row {
            id: icons
            Repeater {
                model: [12, 18, 24, 108]
                SvgIcon {
                    required property int modelData
                    width: modelData
                    height: modelData
                    scale: .7
                    name: "bluetooth"
                }
            }
        }
        Timer {
            interval: 500
            running: true
            onTriggered: {
                for (let icon of icons.children) {
                    if (icon.modelData === undefined)
                        continue;
                    const raster = icon.children[0];
                    // Rasterised at the size it is drawn on screen: no shrinking, no blur.
                    const expected = Math.round(icon.width * .7 * Screen.devicePixelRatio);
                    if (icon.status !== Image.Ready || Math.abs(raster.sourceSize.width - expected) > 1
                            || raster.mipmap || icon.width !== icon.modelData)
                        throw new Error("Icon raster " + raster.sourceSize.width + " for " + expected + " screen pixels");
                }
                console.log("PASS: icons rasterised at their on-screen pixel size, unchanged logical size");
                Qt.quit();
            }
        }
    }
}
