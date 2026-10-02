import QtQuick
import Quickshell
import Quickshell.Io

// Separate entry point: never shares the production ShellId or Wayland connection.
ShellRoot {
    FloatingWindow {
        id: preview
        visible: true
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#080808"
        Item {
            id: frame
            anchors.fill: parent
            Image { anchors.fill: parent; source: Quickshell.env("GHOST_WALLPAPER") || ""; fillMode: Image.PreserveAspectCrop }
            Rail { id: rail; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; previewMode: true }
            SidebarBody {
                visible: controller.page === "sidebar"
                x: 16; y: 82; width: 360; height: 800
                screen: ({name:"HDMI-A-1"})
                previewMode: true
            }
            PanelContent {
                id: panel
                previewMode: true
                x: frame.width / 2 - width / 2
                y: controller.page === "calendar" ? 82 : 68
                width: controller.page === "calendar" ? Math.floor(Math.min(frame.width * 733/1920, (frame.height - 100) * 1200 / 505)) : 392
                height: implicitHeight
                visible: controller.page !== "rail" && controller.page !== "icons" && controller.page !== "sidebar"
                popup: QtObject {
                    id: controller
                    property string page: "calendar"
                    property bool opened: true
                    property real reveal: opened ? 1 : 0
                    Behavior on reveal { NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.panel; easing.type: Easing.OutCubic } }
                }
            }
            Material {
                visible: controller.page === "icons"
                width: 620; height: 320
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
                Row {
                    x: 28; y: 255; spacing: 24
                    Repeater {
                        model: ["search", "app", "terminal", "browser", "folder", "pin"]
                        Icon { required property string modelData; name: modelData; width: 28; height: 28 }
                    }
                    Rectangle {
                        width: 258; height: 40; radius: 4; color: Theme.text
                        Row {
                            anchors.centerIn: parent; spacing: 14
                            Repeater {
                                model: ["search", "app", "terminal", "browser", "folder", "pin"]
                                Icon { required property string modelData; name: modelData; width: 24; height: 24; ink: Theme.base }
                            }
                        }
                    }
                }
            }
            Label { x: 28; anchors.bottom: parent.bottom; anchors.bottomMargin: 24; text: "ghOSt / STAGED RENDER / " + controller.page.toUpperCase() + (Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1" ? " / SAMPLE DATA" : ""); font.pixelSize: 10; color: "white" }
        }
        IpcHandler {
            target: "preview"
            function page(name: string): void { controller.page = name; }
            function metric(name: string): void { Desk.setPerformanceMetric(name); }
            function telemetry(): string { return panel.performanceStatus(); }
            function calendar(action: string, value: string): string { return panel.calendarAction(action,value); }
            function opened(value: bool): void { controller.opened = value; }
            function launcher(action: string, value: string): string { return panel.launcherAction(action, value); }
            function capture(path: string): void { frame.grabToImage(result => { result.saveToFile(path); }); }
            function stop(): void { Qt.quit(); }
        }
    }
}
