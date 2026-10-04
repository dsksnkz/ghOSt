import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: bar
    property var monitor: null
    property var trayWindow: null
    property string screenName: ""
    property bool previewMode: false
    readonly property bool fixtureMode: previewMode && Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1"
    readonly property date displayTime: fixtureMode ? new Date(2026, 8, 29, 9, 21) : Desk.now
    readonly property int displayVolume: fixtureMode ? 33 : Desk.volume
    readonly property var displayWeather: fixtureMode ? ({
            condition: "rain",
            temperature: 20
        }) : Desk.weatherSummary
    function workspaceAction(action, value) {
        if (!fixtureMode)
            return "{}";
        if (action === "current")
            workspaceWheel.fixtureWorkspace = Number(value);
        if (action === "scroll")
            workspaceWheel.scroll(Number(value));
        if (action === "windows")
            workspaceWheel.fixtureWindows = JSON.parse(value.slice(5));
        if (action === "pose")
            workspaceWheel.fixturePose(Number(value));
        if (action === "reduced")
            Theme.reducedMotion = value === "true";
        return JSON.stringify(workspaceWheel.status());
    }
    implicitHeight: 64
    readonly property real designScale: width / 1920
    function open(name, item) {
        const center = item.mapToItem(bar, item.width / 2, 0).x;
        Desk.toggle(name, screenName, Math.max(6, Math.min(width - 398, center - 196)), center);
    }
    Item {
        width: 1920
        height: 64
        scale: bar.designScale
        transformOrigin: Item.TopLeft
        Material {
            x: 19
            y: 16
            width: 1882
            height: 46
            radius: Theme.outerRadius
            gradient: null
            color: "#191919"
            border.width: 0
            G2Surface {
                anchors.fill: parent
                anchors.margins: -1
                radius: Theme.outerRadius + 1
                color: "transparent"
                border.color: "#4d4d4d"
                border.width: 1
            }
            Key {
                x: 19
                y: 7
                width: 42
                height: 32
                hint: "Open controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                SvgIcon {
                    x: 10
                    y: 4
                    width: 24
                    height: 24
                    name: "menu"
                }
            }
            Workspaces {
                id: workspaceWheel
                x: 132
                y: 0
                monitor: bar.monitor
                fixtureWorkspace: bar.fixtureMode ? 5 : -1
            }
            // Hairlines bisect the measured free space between left-hand groups.
            G2Surface {
                x: 96.5
                y: 5
                width: 1
                height: 36
                color: "#3a3a3a"
            }
            G2Surface {
                x: 272.5
                y: 5
                width: 1
                height: 36
                color: "#3a3a3a"
            }
            G2Surface {
                x: 1598
                y: 5
                width: 1
                height: 36
                color: "#3a3a3a"
            }
            G2Surface {
                x: 1821
                y: 5
                width: 1
                height: 36
                color: "#3a3a3a"
            }
            Key {
                x: 314
                y: 7
                width: 260
                height: 32
                hint: "Media controls"
                onClicked: bar.open("media", this)
                onSecondaryClicked: if (Desk.player?.canTogglePlaying)
                    Desk.player.togglePlaying()
                SvgIcon {
                    x: 14
                    y: 6
                    width: 14
                    height: 14
                    name: !bar.fixtureMode && Desk.playing ? "pause" : "play"
                    opacity: !bar.fixtureMode && Desk.playing ? 1 : .4
                }
                Label {
                    x: 42
                    y: 7
                    width: 210
                    text: bar.fixtureMode ? "NO PLAYBACK" : Desk.player?.trackTitle || "NO PLAYBACK"
                    font.pixelSize: 10
                    color: !bar.fixtureMode && Desk.player ? Theme.text : Theme.faint
                }
                G2Surface {
                    x: 14
                    y: 27
                    width: 247
                    height: 1
                    color: "#323232"
                }
            }
            Key {
                x: 853
                y: 5
                width: 218
                height: 36
                hint: "Calendar"
                onClicked: bar.open("calendar", this)
                SvgIcon {
                    id: calendarIcon
                    x: 0
                    y: 8
                    width: 19
                    height: 20
                    name: "calendar"
                }
                InkLabel {
                    id: railTime
                    x: 27
                    y: 0
                    width: 94
                    height: 36
                    text: Qt.formatDateTime(bar.displayTime, "HH:mm")
                    font.family: Theme.font
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
                G2Surface {
                    id: clockDivider
                    x: 123
                    y: 0
                    width: 1
                    height: 36
                    color: "#ffffff"
                }
                Label {
                    x: 143
                    y: 2
                    width: 57
                    height: 16
                    text: Qt.formatDateTime(bar.displayTime, "MM.dd")
                    font.family: Theme.font
                    font.pixelSize: 15
                    color: "#ffffff"
                }
                SvgIcon {
                    x: 143
                    y: 18
                    width: 11
                    height: 16
                    name: bar.displayWeather.condition === "clear" ? "brightness" : bar.displayWeather.condition === "unknown" ? "cloud" : bar.displayWeather.condition
                }
                Label {
                    x: 157
                    y: 18
                    width: 43
                    height: 16
                    text: typeof bar.displayWeather.temperature === "number" ? Math.round(bar.displayWeather.temperature) + "°" : "—"
                    font.family: Theme.font
                    font.pixelSize: 15
                    color: "#ffffff"
                }
            }
            Key {
                x: 1473
                y: 7
                width: 100
                height: 32
                hint: "Sound"
                onClicked: bar.open("audio", this)
                onSecondaryClicked: Desk.mute()
                onScrolled: delta => Desk.setVolume((Desk.volume + (delta > 0 ? 2 : -2)) / 100)
                SvgIcon {
                    id: soundIcon
                    x: 0
                    y: 5
                    width: 22
                    height: 22
                    name: Desk.muted ? "mute" : "volume"
                }
                Meter {
                    x: 30
                    y: 10
                    count: 7
                    segmentWidth: 3
                    spacing: 3
                    value: !bar.fixtureMode && Desk.muted ? 0 : bar.displayVolume / 100
                }
                Label {
                    x: 80
                    y: 9
                    width: 26
                    text: bar.displayVolume
                    font.pixelSize: 10
                    color: Theme.muted
                }
            }
            Key {
                x: 1621
                y: 7
                width: 41
                height: 32
                hint: "Network controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                SvgIcon {
                    id: networkIcon
                    x: 9.5
                    y: 5
                    width: 22
                    height: 22
                    name: bar.fixtureMode ? "wifi" : Desk.wired ? "ethernet" : "wifi"
                    opacity: bar.fixtureMode || Desk.connected ? 1 : .45
                }
            }
            Key {
                x: 1673
                y: 7
                width: 41
                height: 32
                hint: "Bluetooth controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                SvgIcon {
                    id: bluetoothIcon
                    x: 9.5
                    y: 5
                    width: 22
                    height: 22
                    name: "bluetooth"
                    opacity: bar.fixtureMode || Desk.adapter?.enabled ? 1 : .45
                }
            }
            Key {
                x: 1726
                y: 7
                width: 71
                height: 32
                hint: "Battery controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                InkLabel {
                    id: batteryText
                    x: 0
                    y: 0
                    width: 38
                    height: 32
                    text: bar.fixtureMode ? "100%" : Desk.hasBattery ? Desk.charge + "%" : "AC"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
                SvgIcon {
                    id: batteryIcon
                    x: 41
                    y: 5
                    width: 30
                    height: 22
                    name: "battery"
                    visible: Desk.hasBattery || bar.previewMode
                }
            }
            Key {
                x: 1837
                y: 7
                width: 39
                height: 32
                hint: "Power"
                onClicked: bar.open("session", this)
                Canvas {
                    x: 0
                    y: -4
                    width: 39
                    height: 39
                    onPaint: {
                        const c = getContext("2d"), g = c.createRadialGradient(19.5, 19.5, 1, 19.5, 19.5, 18);
                        c.clearRect(0, 0, width, height);
                        g.addColorStop(0, "rgba(255,255,255,.19)");
                        g.addColorStop(1, "rgba(255,255,255,0)");
                        c.fillStyle = g;
                        c.fillRect(0, 0, width, height);
                    }
                }
                SvgIcon {
                    id: powerIcon
                    x: 8.5
                    y: 5
                    width: 22
                    height: 22
                    name: "power"
                }
            }
        }
    }
    function spacingStatus() {
        const icons = [soundIcon, networkIcon, bluetoothIcon, batteryIcon, powerIcon];
        return {
            clockGap: clockDivider.x - railTime.x - railTime.contentWidth,
            clockInkCenter: railTime.mapToItem(bar, 0, railTime.inkCenterY).y,
            calendarIconCenter: calendarIcon.mapToItem(bar, 0, calendarIcon.height / 2).y,
            batteryInkCenter: batteryText.mapToItem(bar, 0, batteryText.inkCenterY).y,
            batteryIconCenter: batteryIcon.mapToItem(bar, 0, batteryIcon.height / 2).y,
            rightIcons: icons.map(icon => ({
                        width: icon.width,
                        height: icon.height,
                        centerY: icon.mapToItem(bar, 0, icon.height / 2).y
                    }))
        };
    }
}
