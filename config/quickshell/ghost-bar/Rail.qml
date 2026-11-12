import QtQuick
import Quickshell
import Quickshell.Hyprland
import "RailLayout.js" as Layout

Item {
    id: bar
    property bool active: true
    property var monitor: null
    property var trayWindow: null
    property string screenName: ""
    property bool previewMode: false
    property var layoutOverride: null
    readonly property var layout: layoutOverride || (previewMode ? null : Settings.state.preferences?.railLayout) || null
    readonly property var positions: layout ? Layout.geometry(layout, controls.width) : ({})
    function elementX(name, original) { return layout ? positions[name]?.x ?? original : original; }
    function elementVisible(name) { return layout ? positions[name]?.visible ?? false : Layout.items.find(item => item.id === name).zone !== "hidden"; }
    readonly property bool fixtureMode: previewMode && Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1"
    readonly property date displayTime: fixtureMode ? new Date(2026, 8, 29, 9, 21) : Desk.now
    readonly property int displayVolume: fixtureMode ? 33 : Desk.volume
    property bool fixtureMedia: false
    // Hidden with no audio; a paused track stays so it can be resumed from the rail.
    readonly property bool mediaRevealed: fixtureMedia || Desk.playing || !!Desk.player?.trackTitle
    property real mediaReveal: mediaRevealed ? 1 : 0
    Behavior on mediaReveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : 280
            easing.type: Easing.OutCubic
        }
    }
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
    // The bar's height sets the scale; the design plane widens with the screen.
    readonly property real designScale: height > 0 ? height / Theme.railHeight : width / 1920
    readonly property real planeWidth: width / designScale
    function open(name, item) {
        const center = item.mapToItem(bar, item.width / 2, 0).x;
        Desk.toggle(name, screenName, Math.max(6, Math.min(width - 398 * designScale, center - 196 * designScale)), center);
    }
    Item {
        width: bar.planeWidth
        height: Theme.railHeight
        scale: bar.designScale
        transformOrigin: Item.TopLeft
        Rectangle {
            anchors.fill: parent
            color: "#191919"
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#404040"
            }
            Item {
                id: controls
                width: bar.planeWidth
                height: 34
                Workspaces {
                    id: workspaceWheel
                    objectName: "rail-element-workspaces"
                    visible: bar.elementVisible("workspaces")
                    x: bar.elementX("workspaces", 15)
                    y: 3
                    monitor: bar.monitor
                    fixtureWorkspace: bar.fixtureMode ? 5 : -1
                }
                Item {
                    objectName: "rail-music-reveal"
                    visible: bar.elementVisible("music") && width > 0
                    x: bar.elementX("music", 150)
                    width: 220 * bar.mediaReveal
                    height: 28
                    clip: true
                    MusicBar {
                        objectName: "rail-element-music"
                        active: bar.active && visible
                        width: 220
                        height: 28
                        onExpanded: bar.open("media", this)
                    }
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    id: centerClock
                    objectName: "rail-clock-control"
                    visible: bar.elementVisible("clock")
                    x: bar.elementX("clock", (controls.width - width) / 2)
                    y: 0
                    width: 124
                    height: 34
                    hint: "Calendar"
                    onClicked: bar.open("calendar", this)
                    InkLabel {
                        id: railTime
                        objectName: "rail-clock-text"
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDateTime(bar.displayTime, "HH:mm")
                        font.family: Theme.font
                        font.pixelSize: 20
                        font.weight: Font.Normal
                        color: "#ffffff"
                    }
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    objectName: "rail-element-network"
                    visible: bar.elementVisible("network")
                    x: bar.elementX("network", controls.width - 300)
                    y: 2
                    width: 38
                    height: 28
                    hint: "Network controls"
                    onClicked: Desk.toggleSidebar(bar.screenName)
                    SvgIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        name: "wifi"
                        opacity: bar.fixtureMode || Desk.connected ? 1 : .45
                    }
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    objectName: "rail-element-bluetooth"
                    visible: bar.elementVisible("bluetooth")
                    x: bar.elementX("bluetooth", controls.width - 260)
                    y: 2
                    width: 38
                    height: 28
                    hint: "Bluetooth controls"
                    onClicked: Desk.toggleSidebar(bar.screenName)
                    SvgIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        name: "bluetooth"
                        opacity: bar.fixtureMode || Desk.adapter?.enabled ? 1 : .45
                    }
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    objectName: "rail-element-volume"
                    visible: bar.elementVisible("volume")
                    x: bar.elementX("volume", controls.width - 218)
                    y: 2
                    width: 38
                    height: 28
                    hint: "Volume controls"
                    wheelEnabled: true
                    onClicked: Desk.toggleSidebar(bar.screenName)
                    onScrolled: delta => Desk.setVolume(Desk.volume / 100 + delta / 120 * .05)
                    SvgIcon {
                        id: volumeIcon
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        name: Desk.muted && !bar.fixtureMode ? "mute" : "volume"
                    }
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    objectName: "rail-element-battery"
                    visible: bar.elementVisible("battery")
                    x: bar.elementX("battery", controls.width - 172)
                    y: 2
                    width: 62
                    height: 28
                    hint: "Battery controls"
                    onClicked: Desk.toggleSidebar(bar.screenName)
                    InkLabel {
                        id: batteryText
                        x: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 28
                        horizontalAlignment: Text.AlignHCenter
                        text: bar.fixtureMode ? "100%" : Desk.hasBattery ? Desk.charge + "%" : "AC"
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: "#ffffff"
                    }
                    SvgIcon {
                        id: batteryIcon
                        x: 41
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        name: "battery"
                        visible: Desk.hasBattery || bar.previewMode
                    }
                }
                Rectangle {
                    x: controls.width - 76
                    visible: !bar.layout
                    y: 1
                    width: 1
                    height: 30
                    color: "#2c2c2c"
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    objectName: "rail-element-power"
                    visible: bar.elementVisible("power")
                    x: bar.elementX("power", controls.width - 62)
                    y: 2
                    width: 38
                    height: 28
                    hint: "Power"
                    onClicked: bar.open("session", this)
                    Canvas {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        onPaint: {
                            const context = getContext("2d");
                            const glow = context.createRadialGradient(17, 17, 3, 17, 17, 17);
                            glow.addColorStop(0, Qt.rgba(1, 1, 1, .12));
                            glow.addColorStop(1, Qt.rgba(1, 1, 1, 0));
                            context.fillStyle = glow;
                            context.fillRect(0, 0, width, height);
                        }
                    }
                    SvgIcon {
                        id: powerIcon
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        name: "power"
                    }
                }
            }
        }
    }
    function spacingStatus() {
        const icons = [volumeIcon, batteryIcon, powerIcon];
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
