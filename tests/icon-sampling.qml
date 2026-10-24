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
                    if (icon.status !== Image.Ready || raster.sourceSize.width < 48
                            || raster.sourceSize.width < icon.width * 2
                            || icon.width !== icon.modelData)
                        throw new Error("Icon texture resolution or logical size changed");
                }
                console.log("PASS: cached high-resolution icons at fractional scale, unchanged logical size");
                Qt.quit();
            }
        }
    }
}
