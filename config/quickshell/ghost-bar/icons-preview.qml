import QtQuick
import Quickshell
import Quickshell.Io
import "IconCatalogue.js" as Catalogue

// Isolated validation entry point: no production ShellId and no desktop actions.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1200
        implicitHeight: 990
        visible: true
        color: "#080808"
        Item {
            id: frame
            anchors.fill: parent
            Label { x: 30; y: 20; text: "ghOSt / SVG SYSTEM     60 ICONS / BLACK + WHITE"; font.pixelSize: 16 }
            Grid {
                x: 24; y: 62; columns: 6; spacing: 6
                Repeater {
                    id: icons
                    model: Catalogue.names
                    delegate: Rectangle {
                        id: tile
                        required property string modelData
                        property bool ready: light.status === Image.Ready && dark.status === Image.Ready
                        width: 186; height: 85; color: "#151515"; radius: 3
                        SvgIcon { id: light; x: 26; y: 12; width: 28; height: 28; name: tile.modelData }
                        Rectangle {
                            x: 104; y: 6; width: 54; height: 40; radius: 3; color: "#ffffff"
                            SvgIcon { id: dark; anchors.centerIn: parent; name: tile.modelData; black: true; width: 28; height: 28 }
                        }
                        Label { x: 10; y: 58; width: parent.width - 20; text: tile.modelData; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
        }
        IpcHandler {
            target: "icons"
            function status(): string {
                let ready = 0;
                for (let i = 0; i < icons.count; i++) if (icons.itemAt(i)?.ready) ready++;
                return JSON.stringify({ready, total: icons.count});
            }
            function capture(path: string): void { frame.grabToImage(result => result.saveToFile(path)); }
            function stop(): void { Qt.quit(); }
        }
    }
}
