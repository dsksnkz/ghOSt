import QtQuick
import Quickshell
import Quickshell.Hyprland
import "RailLayout.js" as Layout

Item {
    id: bar
    property bool active: true
    property string soundGroup: "rail"
    property var monitor: null
    property var trayWindow: null
    property string screenName: ""
    property bool previewMode: false
    property var layoutOverride: null
    readonly property var layout: layoutOverride || (previewMode ? null : Settings.state.preferences?.railLayout) || null
    readonly property var positions: layout ? Layout.geometry(layout, controls.width) : ({})
    function elementX(name, original) { return layout ? positions[name]?.x ?? original : original; }
    function elementVisible(name) { return !layout || (positions[name]?.visible ?? false); }
    readonly property bool fixtureMode: previewMode && Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1"
    readonly property date displayTime: fixtureMode ? new Date(2026, 8, 29, 9, 21) : Desk.now
    readonly property int displayVolume: fixtureMode ? 33 : Desk.volume
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
    implicitHeight: Theme.railHeight
    readonly property real designScale: width / 1920
    function open(name, item) {
        const center = item.mapToItem(bar, item.width / 2, 0).x;
        Desk.toggle(name, screenName, Math.max(6, Math.min(width - 398, center - 196)), center);
    }
    Item {
        width: 1920
        height: Theme.railHeight
        scale: bar.designScale
        transformOrigin: Item.TopLeft
        Material {
            x: 19 * Theme.railOuterGapScale
            y: 16 * Theme.railVerticalScale * Theme.railOuterGapScale
            width: 1920 - 38 * Theme.railOuterGapScale
            height: 46 * Theme.railVerticalScale
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
            Item {
                id: controls
                // Keep the rail full-width; shrink contents uniformly and anchor groups.
                readonly property real extraWidth: width - 1882
                width: parent.width / Theme.railVerticalScale
                height: 46
                scale: Theme.railVerticalScale
                transformOrigin: Item.TopLeft
                Key {
                    objectName: "rail-element-menu"
                    visible: bar.elementVisible("menu")
                    x: bar.elementX("menu", 19)
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
                    objectName: "rail-element-workspaces"
                    visible: bar.elementVisible("workspaces")
                    x: bar.elementX("workspaces", 132)
                    y: 0
                    monitor: bar.monitor
                    fixtureWorkspace: bar.fixtureMode ? 5 : -1
                }
                G2Surface {
                    x: 1598 + controls.extraWidth
                    visible: !bar.layout
                    y: 5
                    width: 1
                    height: 36
                    color: "#3a3a3a"
                }
                G2Surface {
                    x: 1821 + controls.extraWidth
                    visible: !bar.layout
                    y: 5
                    width: 1
                    height: 36
                    color: "#3a3a3a"
                }
                MusicBar {
                    objectName: "rail-element-music"
                    visible: bar.elementVisible("music")
                    active: bar.active && visible
                    x: bar.elementX("music", 314)
                    y: 7
                    width: 260
                    height: 32
                    onExpanded: bar.open("media", this)
                }
                Key {
                    id: centerClock
                    objectName: "rail-clock-control"
                    visible: bar.elementVisible("clock")
                    x: bar.elementX("clock", (controls.width - width) / 2)
                    y: 5
                    width: 124
                    height: 36
                    hint: "Calendar"
                    onClicked: bar.open("calendar", this)
                    InkLabel {
                        id: railTime
                        objectName: "rail-clock-text"
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(bar.displayTime, "HH:mm")
                        font.family: Theme.font
                        font.pixelSize: 26
                        font.weight: Theme.boldWeight
                        color: "#ffffff"
                    }
                }
                Key {
                    objectName: "rail-element-volume"
                    visible: bar.elementVisible("volume")
                    x: bar.elementX("volume", 1473 + controls.extraWidth)
                    y: 7
                    width: 100
                    height: 32
                    hint: "Sound"
                    onClicked: bar.open("audio", this)
                    onSecondaryClicked: Desk.mute()
                    wheelEnabled: true
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
                    objectName: "rail-element-network"
                    visible: bar.elementVisible("network")
                    x: bar.elementX("network", 1621 + controls.extraWidth)
                    y: 7
                    width: 41
                    height: 32
                    hint: "Network controls"
                    onClicked: Desk.toggleSidebar(bar.screenName)
                    SvgIcon {
                        id: networkIcon
                        x: 9.5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 22
                        name: bar.fixtureMode ? "wifi" : Desk.wired ? "ethernet" : "wifi"
                        opacity: bar.fixtureMode || Desk.connected ? 1 : .45
                    }
                }
                Key {
                    objectName: "rail-element-bluetooth"
                    visible: bar.elementVisible("bluetooth")
                    x: bar.elementX("bluetooth", 1673 + controls.extraWidth)
                    y: 7
                    width: 41
                    height: 32
                    hint: "Bluetooth controls"
                    onClicked: Desk.toggleSidebar(bar.screenName)
                    SvgIcon {
                        id: bluetoothIcon
                        x: 9.5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 22
                        name: "bluetooth"
                        opacity: bar.fixtureMode || Desk.adapter?.enabled ? 1 : .45
                    }
                }
                Key {
                    objectName: "rail-element-battery"
                    visible: bar.elementVisible("battery")
                    x: bar.elementX("battery", 1726 + controls.extraWidth)
                    y: 7
                    width: 71
                    height: 32
                    hint: "Battery controls"
                    onClicked: Desk.toggleSidebar(bar.screenName)
                    InkLabel {
                        id: batteryText
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 38
                        height: 32
                        text: bar.fixtureMode ? "100%" : Desk.hasBattery ? Desk.charge + "%" : "AC"
                        font.pixelSize: 12
                        font.weight: Theme.boldWeight
                        color: "#ffffff"
                    }
                    SvgIcon {
                        id: batteryIcon
                        x: 41
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 22
                        name: "battery"
                        visible: Desk.hasBattery || bar.previewMode
                    }
                }
                Key {
                    objectName: "rail-element-power"
                    visible: bar.elementVisible("power")
                    x: bar.elementX("power", 1837 + controls.extraWidth)
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
    }
    function spacingStatus() {
        const icons = [soundIcon, networkIcon, bluetoothIcon, batteryIcon, powerIcon];
        return {
            clockOnly: true,
            railWidth: bar.width,
            clockCenterX: centerClock.mapToItem(bar, centerClock.width / 2, 0).x,
            clockInkCenter: railTime.mapToItem(bar, 0, railTime.inkCenterY).y,
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
