import QtQuick
import Quickshell
import Quickshell.Io

// Separate entry point: never shares the production ShellId or Wayland connection.
ShellRoot {
    FloatingWindow {
        id: preview
        visible: true
        implicitWidth: 1600
        implicitHeight: 820
        color: "#080808"
        Item {
            id: frame
            anchors.fill: parent
            Image { anchors.fill: parent; source: Quickshell.env("GHOST_WALLPAPER"); fillMode: Image.PreserveAspectCrop }
            Rail { id: rail; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; previewMode: true }
            PanelContent {
                id: panel
                x: frame.width / 2 - width / 2
                y: 52
                width: 392
                height: implicitHeight
                visible: controller.page !== "rail" && controller.page !== "icons"
                popup: QtObject {
                    id: controller
                    property string page: "calendar"
                    property bool opened: true
                    property real reveal: 1
                }
            }
            Material {
                visible: controller.page === "icons"
                width: 620; height: 250
                anchors.centerIn: parent
                Label { x: 28; y: 24; text: "ghOSt / ICONS"; font.pixelSize: 11; color: Theme.muted }
                BrandMark { x: 28; y: 65; width: 48; height: 48 }
                Row {
                    x: 106; y: 78; spacing: 22
                    Repeater {
                        model: ["wifi", "bluetooth", "volume", "battery", "network", "calendar", "power", "cpu", "gpu"]
                        Icon { required property string modelData; name: modelData; width: 28; height: 28 }
                    }
                }
                Rectangle {
                    x: 22; y: 140; width: parent.width - 44; height: 80; radius: 5; color: Theme.text
                    BrandMark { x: 10; y: 12; width: 48; height: 48; ink: Theme.base }
                    Row {
                        x: 84; y: 24; spacing: 22
                        Repeater {
                            model: ["wifi", "bluetooth", "volume", "battery", "network", "calendar", "power", "cpu", "gpu"]
                            Icon { required property string modelData; name: modelData; width: 28; height: 28; ink: Theme.base }
                        }
                    }
                }
            }
            Label { x: 28; anchors.bottom: parent.bottom; anchors.bottomMargin: 24; text: "ghOSt / STAGED RENDER / " + controller.page.toUpperCase(); font.pixelSize: 10; color: "white" }
        }
        IpcHandler {
            target: "preview"
            function page(name: string): void { controller.page = name; }
            function metric(name: string): void { Desk.setPerformanceMetric(name); }
            function telemetry(): string { return panel.performanceStatus(); }
            function capture(path: string): void { frame.grabToImage(result => { result.saveToFile(path); }); }
            function stop(): void { Qt.quit(); }
        }
    }
}
