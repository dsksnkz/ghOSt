import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.UPower
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
    readonly property bool networkLit: fixtureMode || Networking.wifiEnabled || !!Desk.wired
    readonly property date displayTime: fixtureMode ? new Date(2026, 8, 29, 9, 21) : Desk.now
    readonly property int displayVolume: fixtureMode ? 33 : Desk.volume
    property bool fixtureMedia: false
    // Hidden with no audio; a paused track stays so it can be resumed from the rail.
    readonly property bool mediaRevealed: fixtureMedia || Desk.playing || !!Desk.player?.trackTitle
    property real mediaReveal: mediaRevealed ? 1 : 0
    // Volume and brightness changes replace the clock for a moment.
    readonly property bool levelShown: !previewMode && OsdState.railOpened && OsdState.railScreen === screenName
    property real levelReveal: levelShown ? 1 : 0
    Behavior on levelReveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : 220
            easing.type: Easing.OutCubic
        }
    }
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
        // Panel width, design units: the Wi-Fi and Bluetooth menus are wider.
        const panel = name === "network" || name === "bluetooth" || name === "battery" ? 430 : 392;
        Desk.toggle(name, screenName, Math.max(6, Math.min(width - (panel + 6) * designScale, center - panel / 2 * designScale)), center);
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
                        opacity: 1 - bar.levelReveal
                    }
                }
                Item {
                    id: level
                    objectName: "rail-level"
                    readonly property real amount: Math.max(0, Math.min(100, OsdState.amount))
                    property real shown: amount
                    Behavior on shown {
                        enabled: !Theme.reducedMotion
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                    visible: bar.levelReveal > 0.01
                    opacity: bar.levelReveal
                    width: 300
                    height: 26
                    x: (centerClock.visible ? centerClock.x + centerClock.width / 2 : controls.width / 2) - width / 2
                    y: (34 - height) / 2
                    SvgIcon {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        name: OsdState.kind === "brightness" ? "brightness" : Desk.muted ? "mute" : "volume"
                    }
                    Rectangle {
                        id: track
                        x: 36
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 36 - 44
                        height: 4
                        radius: 2
                        color: "#333333"
                        Rectangle {
                            width: parent.width * level.shown / 100
                            height: parent.height
                            radius: 2
                            color: Desk.muted && OsdState.kind === "volume" ? "#6a6a6a" : "#e8e8e8"
                        }
                    }
                    InkLabel {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 18
                        horizontalAlignment: Text.AlignRight
                        text: OsdState.available ? Math.round(level.amount) : "—"
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: "#9c9c9c"
                    }
                    // Scrolling here keeps adjusting the same level.
                    WheelHandler {
                        onWheel: event => {
                            OsdState.railMove(level.amount + (event.angleDelta.y > 0 ? 2 : event.angleDelta.y < 0 ? -2 : 0));
                            event.accepted = true;
                        }
                    }
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    objectName: "rail-element-network"
                    visible: bar.elementVisible("network")
                    x: bar.elementX("network", controls.width - 229)
                    y: 2
                    width: 28
                    height: 28
                    hint: "Wi-Fi"
                    onClicked: bar.open("network", this)
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: "#d9d9d9"
                        // Lit while any link is up: Wi-Fi on, or a cable plugged in.
                        opacity: bar.networkLit ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: Theme.reducedMotion ? 0 : 140 }
                        }
                    }
                    SvgIcon {
                        id: networkIcon
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        name: Desk.wired && !Desk.network && !bar.fixtureMode ? "ethernet" : "wifi"
                        black: bar.networkLit
                    }
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    objectName: "rail-element-bluetooth"
                    visible: bar.elementVisible("bluetooth")
                    x: bar.elementX("bluetooth", controls.width - 187)
                    y: 2
                    width: 28
                    height: 28
                    hint: "Bluetooth"
                    onClicked: bar.open("bluetooth", this)
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: "#d9d9d9"
                        opacity: bar.fixtureMode || !!Desk.adapter?.enabled ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: Theme.reducedMotion ? 0 : 140 }
                        }
                    }
                    SvgIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        name: "bluetooth"
                        black: bar.fixtureMode || !!Desk.adapter?.enabled
                    }
                }
                Key {
                    hoverFeedback: false
                    pressFeedback: false
                    objectName: "rail-element-volume"
                    visible: bar.elementVisible("volume")
                    x: bar.elementX("volume", controls.width - 150)
                    y: 2
                    width: 28
                    height: 28
                    hint: "Volume controls"
                    wheelEnabled: true
                    onClicked: bar.open("audio", this)
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
                    id: batteryKey
                    // A desktop without a battery has nothing to show here.
                    visible: bar.elementVisible("battery") && (Desk.hasBattery || bar.previewMode)
                    x: bar.elementX("battery", controls.width - 122)
                    y: 2
                    width: 40
                    height: 28
                    hint: "Battery " + Desk.charge + "%"
                    onClicked: bar.open("battery", this)
                    readonly property bool charging: Desk.battery?.state === UPowerDeviceState.Charging || Desk.battery?.state === UPowerDeviceState.PendingCharge
                    // A horizontal battery with the level written inside it.
                    SvgIcon {
                        visible: batteryKey.charging
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        name: "lightning"
                    }
                    Rectangle {
                        id: batteryBody
                        x: 10
                        y: 8
                        width: 26
                        height: 13
                        radius: 4
                        color: "transparent"
                        border.width: 1
                        border.color: Desk.charge <= 15 && !batteryKey.charging ? "#e08a8a" : "#bdbdbd"
                        Rectangle {
                            x: 2
                            y: 2
                            width: Math.round((parent.width - 4) * Math.max(0, Math.min(100, bar.fixtureMode ? 100 : Desk.charge)) / 100)
                            height: parent.height - 4
                            radius: 2
                            color: "#ffffff"
                            opacity: .16
                        }
                        Text {
                            anchors.centerIn: parent
                            text: bar.fixtureMode ? "100" : Desk.charge
                            font.family: Theme.font
                            font.pixelSize: 9
                            font.weight: Theme.demiWeight
                            color: "#ffffff"
                        }
                    }
                    Rectangle {
                        x: batteryBody.x + batteryBody.width + 1
                        y: batteryBody.y + 4
                        width: 2
                        height: 5
                        radius: 1
                        color: "#bdbdbd"
                    }
                }
                Rectangle {
                    x: bar.elementX("power", controls.width - 62) - 16
                    visible: bar.elementVisible("power") && batteryKey.visible
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
        const icons = [networkIcon, volumeIcon, powerIcon];
        return {
            clockOnly: true,
            railWidth: bar.width,
            clockCenterX: centerClock.mapToItem(bar, centerClock.width / 2, 0).x,
            clockInkCenter: railTime.mapToItem(bar, 0, railTime.inkCenterY).y,
            batteryIconCenter: batteryBody.mapToItem(bar, 0, batteryBody.height / 2).y,
            rightIcons: icons.map(icon => ({
                        width: icon.width,
                        height: icon.height,
                        centerY: icon.mapToItem(bar, 0, icon.height / 2).y
                    }))
        };
    }
}
