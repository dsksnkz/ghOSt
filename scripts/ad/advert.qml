import QtQuick
import Quickshell
import Quickshell.Io

// Asset renderer only: this entry point never joins the desktop Wayland session.
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#151515"
        Item {
            id: stage
            anchors.fill: parent
            property string scene: "rail"
            Rail {
                id: rail
                visible: stage.scene === "rail"
                width: 1920
                height: 50
                previewMode: true
            }
            G2Surface {
                id: calendarFrame
                visible: stage.scene === "calendar"
                width: 820
                height: 347
                radius: 7
                color: "#151515"
                border.color: "#474747"
                border.width: 1
                gradient: Gradient {
                    GradientStop { position: 0; color: "#161616" }
                    GradientStop { position: 1; color: "#1c1c1c" }
                }
                CalendarPanel {
                    id: calendar
                    anchors.fill: parent
                    previewMode: true
                    active: calendarFrame.visible
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
        }
        IpcHandler {
            target: "advert"
            function frame(scene: string, params: string, path: string): void {
                const state = JSON.parse(params);
                stage.scene = scene;
                let item;
                if (scene === "rail") {
                    rail.fixtureVolume = state.volume ?? 33;
                    rail.workspaceAction("pose", String(state.pose ?? 0));
                    item = rail;
                } else if (scene === "calendar") {
                    calendar.elapsed = state.elapsed ?? 1500;
                    calendar.order = [2, 0, 4, 1, 3, 5];
                    calendar.readings = {
                        gpu: state.gpu ?? 32, cpu: state.cpu ?? 20,
                        memory: 48, processor: 2800, maximum: 4600
                    };
                    calendar.clockMetric = state.clock ?? false;
                    calendar.month = new Date(2026, state.month ?? 8, 1);
                    if (state.condition) {
                        const sample = Object.assign({}, calendar.weather);
                        sample.condition = state.condition;
                        sample.days = sample.days.map((day, index) => index === 2
                            ? Object.assign({}, day, {condition: state.condition}) : day);
                        calendar.weather = sample;
                    }
                    item = calendarFrame;
                } else if (scene === "sidebar") {
                    sidebar.reveal = state.reveal ?? 1;
                    sidebar.entranceOrder = [3, 1, 4, 0, 2, 5];
                    sidebar.entranceTime = state.elapsed ?? 900;
                    item = sidebarFrame;
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
