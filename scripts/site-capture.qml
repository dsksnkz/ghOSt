import QtQuick
import Quickshell
import Quickshell.Io

// Website asset renderer: real ghOSt components with sample data only.
ShellRoot {
    FloatingWindow {
        visible: true
        title: "ghOSt Settings"
        implicitWidth: 1024
        implicitHeight: 699
        color: "#0b0b0c"
        Item {
            id: stage
            anchors.fill: parent
            property string scene: ""
            Rail {
                id: rail
                visible: stage.scene === "rail"
                width: 1920
                height: Theme.railHeight
                previewMode: true
                fixtureMedia: true
            }
            G2Surface {
                id: calendarFrame
                visible: stage.scene === "calendar"
                width: Theme.calendarWidth(1920, 1080)
                height: Math.round(width * Theme.calendarPlaneHeight / Theme.calendarPlaneWidth)
                radius: Theme.outerRadius
                color: "#0b0b0b"
                border.color: "#272727"
                border.width: 1
                CalendarPanel {
                    id: calendar
                    anchors.fill: parent
                    previewMode: true
                    active: false
                }
            }
            Item {
                id: sidebarFrame
                visible: stage.scene === "sidebar"
                width: 410
                height: 914
                SidebarFigmaBody {
                    id: sidebar
                    y: 2.3
                    width: 407.7
                    height: 909.4
                    previewMode: true
                    screen: ({name: "HDMI-A-1"})
                    opened: sidebarFrame.visible
                }
            }
            SettingsPanel {
                id: settings
                visible: stage.scene === "settings"
                width: 1024
                height: 699
                previewMode: true
            }
            G2Surface {
                id: launcherFrame
                visible: stage.scene === "launcher"
                width: 560
                height: 328
                color: "#191919"
                radius: 22
                smoothing: 0.6
                border.width: 1
                border.color: "#333333"
                Launcher {
                    id: launcher
                    x: 16
                    y: 16
                    width: 528
                    previewMode: true
                }
            }
            G2Surface {
                id: mediaFrame
                visible: stage.scene === "media"
                width: 420
                height: media.implicitHeight
                radius: Theme.outerRadius
                color: "#0b0b0b"
                border.color: "#272727"
                border.width: 1
                MediaPanel {
                    id: media
                    width: parent.width
                    active: mediaFrame.visible
                }
            }
            SwitcherScene {
                id: switcher
                visible: stage.scene === "switcher"
                width: 1920
                height: 1080
                previewMode: true
                open: visible
            }
        }
        IpcHandler {
            target: "site"
            function frame(scene: string, path: string): void {
                stage.scene = scene;
                let item = rail;
                if (scene === "calendar") {
                    calendar.elapsed = 1500;
                    calendar.order = [2, 0, 4, 1, 3, 5];
                    calendar.readings = {gpu: 34, cpu: 22, memory: 46, processor: 2800, maximum: 4600};
                    item = calendarFrame;
                } else if (scene === "sidebar") {
                    sidebar.reveal = 1;
                    sidebar.entranceOrder = [3, 1, 4, 0, 2, 5];
                    sidebar.entranceTime = 900;
                    item = sidebarFrame;
                } else if (scene === "settings") {
                    settings.choose("general");
                    item = settings;
                } else if (scene === "launcher") {
                    item = launcherFrame;
                } else if (scene === "media") {
                    item = mediaFrame;
                } else if (scene === "switcher") {
                    item = switcher;
                }
                settle.item = item;
                settle.path = path;
                settle.restart();
            }
            function stop(): void { Qt.quit(); }
        }
        // Gives motion, images and blur passes time to settle before the grab.
        Timer {
            id: settle
            property var item
            property string path
            interval: 1400
            onTriggered: item.grabToImage(result => result.saveToFile(path),
                Qt.size(Math.round(item.width * 2), Math.round(item.height * 2)))
        }
    }
}
