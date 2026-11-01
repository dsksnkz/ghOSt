import QtQuick
import Quickshell
import Quickshell.Io

// Asset renderer for the showreel: real ghOSt components with sample data,
// offscreen only. It never joins the desktop session or changes system state.
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#0b0b0c"
        Item {
            id: stage
            anchors.fill: parent
            property string scene: "rail"
            Rail {
                id: rail
                visible: stage.scene === "rail"
                width: 1920
                height: Theme.railHeight
                previewMode: true
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
                    // Inactive: the reel drives the reveal frame by frame.
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
            IntroPanel {
                id: intro
                visible: stage.scene === "intro"
                width: 860
                height: 620
            }
            NotificationBanner {
                id: toast
                visible: stage.scene === "toast"
                width: 360
                notification: ({app: "Music", summary: "Now playing", body: "Midnight City - M83"})
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
        }
        IpcHandler {
            target: "reel"
            function frame(scene: string, params: string, path: string): void {
                const state = JSON.parse(params);
                stage.scene = scene;
                let item;
                if (scene === "rail") {
                    rail.workspaceAction("pose", String(state.pose ?? 0));
                    item = rail;
                } else if (scene === "calendar") {
                    calendar.elapsed = state.elapsed ?? 1500;
                    calendar.order = [2, 0, 4, 1, 3, 5];
                    if (state.forecast !== undefined)
                        calendar.selectForecast(state.forecast);
                    calendar.readings = {
                        gpu: state.gpu ?? 34, cpu: state.cpu ?? 22,
                        memory: state.memory ?? 46, processor: 2800, maximum: 4600
                    };
                    item = calendarFrame;
                } else if (scene === "sidebar") {
                    sidebar.reveal = state.reveal ?? 1;
                    sidebar.entranceOrder = [3, 1, 4, 0, 2, 5];
                    sidebar.entranceTime = state.elapsed ?? 900;
                    item = sidebarFrame;
                } else if (scene === "media") {
                    if (state.levels)
                        Theme.reelLevels = state.levels;
                    item = mediaFrame;
                } else if (scene === "launcher") {
                    launcher.query = state.query ?? "";
                    item = launcherFrame;
                } else if (scene === "intro") {
                    item = intro;
                } else if (scene === "toast") {
                    item = toast;
                } else {
                    settings.choose(state.page ?? "general");
                    item = settings;
                }
                Qt.callLater(() => item.grabToImage(result => result.saveToFile(path),
                    Qt.size(Math.round(item.width * 2), Math.round(item.height * 2))));
            }
            function stop(): void { Qt.quit(); }
        }
    }
}
