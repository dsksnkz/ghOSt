import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower

Item {
    id: content
    required property var popup
    property bool previewMode: false
    signal settingsPreviewRequested
    function focusPage() {
        if (pageLoader.item?.focusSearch)
            pageLoader.item.focusSearch();
        else
            content.forceActiveFocus();
    }
    function launcherAction(action, value) {
        const item = pageLoader.item;
        if (popup.page !== "launcher" || !item)
            return "";
        if (action === "query")
            item.query = value;
        if (action === "move")
            item.move(Number(value));
        if (action === "pin")
            item.pin(item.results.find(e => e.id === value));
        if (action === "launch" && previewMode)
            item.launch(item.results.find(e => e.id === value));
        return item.status();
    }
    function performanceStatus() {
        if (pageLoader.item?.status)
            return pageLoader.item.status();
        const gauge = pageLoader.item?.telemetry;
        return JSON.stringify(gauge ? {
            metric: gauge.metric,
            value: gauge.reading,
            maximum: gauge.maximum,
            active: gauge.active
        } : {
            active: false
        });
    }
    function calendarAction(action, value) {
        const item = pageLoader.item;
        if (popup.page !== "calendar" || !item)
            return "";
        if (action === "reveal")
            item.beginReveal();
        if (action === "month")
            item.monthStep(Number(value));
        if (action === "reduced")
            Theme.reducedMotion = value === "true";
        if (action === "weather" && previewMode)
            item.weather = {
                condition: value,
                temperature: 15,
                days: []
            };
        if (action === "level" && previewMode)
            item.readings = {
                cpu: Number(value),
                gpu: Number(value),
                memory: Number(value),
                processor: 2100,
                maximum: 4500
            };
        if (action === "clock" && previewMode)
            item.clockMetric = value === "true";
        if (action === "action" && previewMode)
            item.actionPage = value;
        if (action === "navigate" && previewMode) {
            const previousStatus = item.status();
            item.navigateRequested(value);
            return previousStatus;
        }
        return item.status();
    }
    implicitHeight: body.implicitHeight + (popup.page === "calendar" ? 0 : 46)
    focus: true
    Keys.onEscapePressed: {
        if (popup.page === "calendar" && pageLoader.item?.actionPage)
            pageLoader.item.actionPage = "";
        else if (content.previewMode)
            popup.opened = false;
        else
            Desk.close();
    }
    opacity: popup.reveal
    transform: [
        Translate {
            y: (popup.page === "calendar" ? -24 : -8) * (1 - popup.reveal)
        },
        Scale {
            origin.x: Desk.panelOrigin
            origin.y: 0
            xScale: popup.page === "calendar" ? 1 : .18 + .82 * popup.reveal
            yScale: popup.page === "calendar" ? 1 : .1 + .9 * popup.reveal
        }
    ]
    Material {
        visible: popup.page !== "calendar"
        anchors.fill: parent
        anchors.margins: 1
        radius: Theme.outerRadius
    }
    Material {
        visible: popup.page === "calendar"
        anchors.fill: parent
        radius: Theme.outerRadius
    }
    Column {
        id: body
        x: popup.page === "calendar" ? 0 : 22
        y: popup.page === "calendar" ? 0 : 19
        width: parent.width - (popup.page === "calendar" ? 0 : 44)
        spacing: popup.page === "calendar" ? 0 : 17
        Row {
            visible: popup.page !== "calendar"
            width: parent.width
            Column {
                width: parent.width - 32
                spacing: 5
                Label {
                    text: popup.page === "session" ? "ghOSt" : "ghOSt / " + popup.page.toUpperCase()
                    color: Theme.muted
                    font.pixelSize: 9
                    font.letterSpacing: 1.1
                }
                Label {
                    text: ({
                            launcher: "Applications",
                            audio: "Sound",
                            network: "Connections",
                            bluetooth: "Bluetooth",
                            calendar: Qt.formatDateTime(Desk.now, "MMMM yyyy"),
                            media: "Now playing",
                            battery: "Power",
                            session: "Power"
                        })[popup.page] || ""
                    font.pixelSize: 19
                    font.weight: Font.Normal
                }
            }
            Key {
                width: 30
                hint: "Close"
                onClicked: Desk.close()
                Icon {
                    anchors.centerIn: parent
                    name: "close"
                    width: 16
                    height: 16
                }
            }
        }
        G2Surface {
            visible: popup.page !== "calendar"
            width: parent.width
            height: 1
            color: Theme.line
        }
        Loader {
            id: pageLoader
            width: parent.width
            sourceComponent: ({
                    launcher: launcherPage,
                    audio: audioPage,
                    network: networkPage,
                    bluetooth: bluetoothPage,
                    calendar: calendarPage,
                    media: mediaPage,
                    battery: batteryPage,
                    session: sessionPage
                })[popup.page] || null
            onLoaded: {
                if (popup.page !== "calendar")
                    pageEntrance.restart();
                else
                    pageLoader.opacity = 1;
                Qt.callLater(content.focusPage);
            }
            NumberAnimation {
                id: pageEntrance
                target: pageLoader
                property: "opacity"
                from: 0.35
                to: 1
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
        Label {
            width: parent.width
            visible: Desk.notice !== ""
            text: Desk.notice
            wrapMode: Text.WordWrap
            color: Theme.orange
        }
    }
    component Action: Key {
        width: body.width
        height: 36
        color: Theme.surface
        border.color: Theme.line
        border.width: 1
    }
    component Caption: Label {
        font.pixelSize: 9
        font.letterSpacing: 1
        color: Theme.muted
    }
    Component {
        id: launcherPage
        Launcher {
            previewMode: content.previewMode
        }
    }
    Component {
        id: audioPage
        Column {
            spacing: 18
            Row {
                width: parent.width
                Label {
                    width: parent.width - 85
                    text: Desk.sink?.description || "No output device"
                    wrapMode: Text.WordWrap
                    font.pixelSize: 11
                }
                Label {
                    text: String(Desk.volume).padStart(2, "0")
                    font.pixelSize: 32
                    color: Desk.muted ? Theme.faint : Theme.cream
                }
            }
            Controls.Slider {
                id: volumeSlider
                width: parent.width
                height: 34
                from: 0
                to: 1
                stepSize: 0.01
                value: Desk.volume / 100
                enabled: !!Desk.audio
                onMoved: Desk.setVolume(value)
                background: Item {
                    x: volumeSlider.leftPadding
                    y: (volumeSlider.height - height) / 2
                    width: volumeSlider.availableWidth
                    height: 18
                    Meter {
                        count: 40
                        segmentWidth: 5
                        spacing: 3
                        value: volumeSlider.visualPosition
                        ink: Theme.cream
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                handle: G2Surface {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: (volumeSlider.height - height) / 2
                    width: 4
                    height: 24
                    radius: 1
                    color: Theme.orange
                }
                Accessible.name: "Output volume"
            }
            Row {
                spacing: 8
                Action {
                    width: (body.width - 8) / 2
                    text: Desk.muted ? "Unmute" : "Mute"
                    onClicked: Desk.mute()
                }
                Action {
                    width: (body.width - 8) / 2
                    text: "Audio settings ↗"
                    onClicked: Desk.launch(["pavucontrol"])
                }
            }
            Caption {
                text: "OUTPUT / PIPEWIRE"
            }
        }
    }
    Component {
        id: networkPage
        Column {
            spacing: 13
            Row {
                spacing: 12
                Icon {
                    width: 28
                    height: 28
                    name: Desk.wired ? "network" : "wifi"
                    ink: Desk.connected ? Theme.text : Theme.faint
                }
                Column {
                    spacing: 4
                    Label {
                        width: body.width - 52
                        text: Desk.networkName
                        font.pixelSize: 13
                    }
                    Caption {
                        text: Desk.connected ? "CONNECTED" : "DISCONNECTED"
                    }
                }
            }
            Action {
                text: "Wi-Fi                              " + (Networking.wifiEnabled ? "ON" : "OFF")
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
            Caption {
                text: "SAVED / NEARBY"
            }
            Repeater {
                model: Desk.wifi ? Desk.wifi.networks.values.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength).slice(0, 5) : []
                delegate: Action {
                    required property var modelData
                    text: (modelData.connected ? "● " : "○ ") + modelData.name + (modelData.known ? "" : " ↗")
                    ink: modelData.connected ? Theme.cream : Theme.muted
                    onClicked: {
                        if (modelData.connected)
                            return;
                        if (modelData.known) {
                            modelData.connect();
                            Desk.notice = "Connecting to " + modelData.name + "…";
                        } else
                            Desk.launch(["nm-connection-editor"]);
                    }
                    Connections {
                        target: modelData
                        function onConnectionFailed(reason) {
                            Desk.notice = "Connection failed: " + ConnectionFailReason.toString(reason);
                        }
                        function onConnectedChanged() {
                            if (modelData.connected)
                                Desk.notice = "";
                        }
                    }
                }
            }
            Action {
                text: "Network settings ↗"
                onClicked: Desk.launch(["nm-connection-editor"])
            }
        }
    }
    Component {
        id: bluetoothPage
        Column {
            spacing: 14
            Action {
                text: Desk.adapter ? "Bluetooth                          " + (Desk.adapter.enabled ? "ON" : "OFF") : "No Bluetooth adapter"
                enabled: !!Desk.adapter
                onClicked: Desk.adapter.enabled = !Desk.adapter.enabled
            }
            Repeater {
                model: Bluetooth.devices.values.filter(d => d.paired || d.connected).slice(0, 6)
                delegate: Action {
                    required property var modelData
                    text: (modelData.connected ? "● " : "○ ") + modelData.name
                    onClicked: Desk.launch(["blueman-manager"])
                }
            }
            Action {
                text: "Pair & manage devices ↗"
                onClicked: Desk.launch(["blueman-manager"])
            }
        }
    }
    Component {
        id: calendarPage
        CalendarPanel {
            active: popup.opened && popup.page === "calendar"
            previewMode: content.previewMode
            onNavigateRequested: page => {
                if (page === "settings") {
                    if (content.previewMode)
                        content.settingsPreviewRequested();
                    else
                        Desk.openSettings(Desk.panelScreen);
                } else if (content.previewMode)
                    popup.page = page;
                else
                    Desk.panel = page;
            }
        }
    }
    Component {
        id: mediaPage
        Column {
            spacing: 17
            Label {
                width: parent.width
                text: Desk.player?.trackTitle || "Nothing playing"
                font.pixelSize: 19
                wrapMode: Text.WordWrap
            }
            Label {
                width: parent.width
                text: Desk.player?.trackArtist || "Media appears here when playback starts."
                color: Theme.muted
                wrapMode: Text.WordWrap
            }
            Row {
                spacing: 8
                Action {
                    width: (body.width - 16) / 3
                    text: " previous"
                    enabled: Desk.player?.canGoPrevious ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: Desk.player.previous()
                }
                Action {
                    width: (body.width - 16) / 3
                    text: Desk.playing ? "pause" : "play"
                    enabled: Desk.player?.canTogglePlaying ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: Desk.player.togglePlaying()
                }
                Action {
                    width: (body.width - 16) / 3
                    text: "next "
                    enabled: Desk.player?.canGoNext ?? false
                    opacity: enabled ? 1 : 0.35
                    onClicked: Desk.player.next()
                }
            }
            Caption {
                text: Desk.player?.identity || "MPRIS"
            }
        }
    }
    Component {
        id: batteryPage
        Column {
            spacing: 19
            Label {
                text: Desk.hasBattery ? Desk.charge + "%" : "AC"
                font.pixelSize: 56
                font.weight: Font.Light
                color: Theme.cream
            }
            Meter {
                count: 40
                segmentWidth: 5
                value: Desk.charge / 100
                ink: Desk.charge < 20 ? Theme.orange : Theme.cream
            }
            Caption {
                text: Desk.hasBattery ? UPowerDeviceState.toString(Desk.battery.state).toUpperCase() : "EXTERNAL POWER"
            }
            Label {
                text: Desk.battery?.state === UPowerDeviceState.Discharging && Desk.battery.timeToEmpty > 0 && Desk.battery.timeToEmpty < 259200 ? Math.floor(Desk.battery.timeToEmpty / 3600) + "h " + Math.floor(Desk.battery.timeToEmpty % 3600 / 60) + "m remaining" : Desk.battery?.state === UPowerDeviceState.Charging && Desk.battery.timeToFull > 0 && Desk.battery.timeToFull < 259200 ? Math.ceil(Desk.battery.timeToFull / 60) + "m until full" : ""
                visible: text !== ""
                color: Theme.muted
            }
        }
    }
    Component {
        id: sessionPage
        Column {
            id: sessionBody
            property string pending: ""
            width: body.width
            spacing: 8
            Repeater {
                model: [
                    {
                        label: "Lock",
                        icon: "lock",
                        command: []
                    },
                    {
                        label: "Sleep",
                        icon: "sleep",
                        command: ["systemctl", "suspend"]
                    },
                    {
                        label: "Log out",
                        icon: "logout",
                        command: ["hyprctl", "dispatch", "exit"]
                    },
                    {
                        label: "Restart",
                        icon: "restart",
                        command: ["systemctl", "reboot"]
                    },
                    {
                        label: "Shut down",
                        icon: "power",
                        command: ["systemctl", "poweroff"]
                    }
                ]
                Key {
                    required property var modelData
                    width: sessionBody.width
                    height: 42
                    radius: Theme.innerRadius(3)
                    color: sessionBody.pending === modelData.label ? "#373737" : "#222222"
                    border.color: Theme.line
                    border.width: 1
                    hint: modelData.label
                    onClicked: {
                        if (content.previewMode) {
                            Desk.notice = "Preview — system actions disabled";
                            return;
                        }
                        if (modelData.command.length === 0) {
                            Desk.notice = "Lock needs an independent ghOSt configuration";
                            return;
                        }
                        if (sessionBody.pending === modelData.label) {
                            Desk.launch(modelData.command);
                            return;
                        }
                        sessionBody.pending = modelData.label;
                        Desk.notice = "Confirm " + modelData.label.toLowerCase() + " or cancel";
                    }
                    Row {
                        x: 13
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        SvgIcon {
                            width: 19
                            height: 19
                            name: modelData.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: sessionBody.pending === modelData.label ? "Confirm " + modelData.label : modelData.label
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
            Key {
                width: sessionBody.width
                height: 34
                text: "Cancel"
                visible: sessionBody.pending !== ""
                hint: "Cancel power action"
                onClicked: {
                    sessionBody.pending = "";
                    Desk.notice = "";
                }
            }
        }
    }
}
