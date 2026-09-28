import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower

PanelWindow {
    id: popup
    property var companion
    property string page: ""
    property bool opened: false
    property real reveal: opened ? 1 : 0
    function syncPanel() {
        const show = Desk.panel !== "" && Desk.panelScreen === screen.name;
        if (show) page = Desk.panel;
        opened = show;
    }
    onOpenedChanged: {
        Qt.callLater(() => {
            if (opened) content.forceActiveFocus();
            focusGrab.active = opened;
        });
    }
    Component.onCompleted: syncPanel()
    Connections {
        target: Desk
        function onPanelChanged() { popup.syncPanel(); }
        function onPanelScreenChanged() { popup.syncPanel(); }
    }
    anchors { top: true; left: true }
    margins.top: 52
    margins.left: Math.round(Math.max(6, Math.min(screen.width - 398, Desk.panelX)))
    implicitWidth: Math.min(392, screen.width - 12)
    implicitHeight: body.implicitHeight + 46
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    visible: opened || reveal > 0.001
    Behavior on reveal { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    HyprlandFocusGrab { id: focusGrab; windows: popup.companion ? [popup, popup.companion] : [popup]; onCleared: Qt.callLater(Desk.close) }
    Item {
        id: content
        anchors.fill: parent; focus: true
        Keys.onEscapePressed: Desk.close()
        opacity: popup.reveal
        transform: Translate { y: -10 * (1 - popup.reveal) }
        Material { anchors.fill: parent; anchors.margins: 1; radius: 10 }
        Column {
            id: body
            x: 22; y: 19; width: parent.width - 44; spacing: 17
            Row {
                width: parent.width
                Column {
                    width: parent.width - 32; spacing: 5
                    Label { text: "ghOSt / " + popup.page.toUpperCase(); color: Theme.muted; font.pixelSize: 9; font.letterSpacing: 1.1 }
                    Label { text: ({audio:"Sound", network:"Connections", bluetooth:"Bluetooth", calendar:Qt.formatDateTime(Desk.now,"MMMM yyyy"),media:"Now playing",battery:"Power",session:"Your session"})[popup.page] || ""; font.pixelSize: 19; font.weight: Font.Normal }
                }
                Key { text: "×"; width: 30; hint: "Close"; onClicked: Desk.close() }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.line }
            Loader {
                id: pageLoader
                width: parent.width
                sourceComponent: ({audio:audioPage, network:networkPage, bluetooth:bluetoothPage, calendar:calendarPage, media:mediaPage, battery:batteryPage, session:sessionPage})[popup.page] || null
                onLoaded: pageEntrance.restart()
                NumberAnimation { id: pageEntrance; target: pageLoader; property: "opacity"; from: 0.35; to: 1; duration: 120; easing.type: Easing.OutCubic }
            }
            Label { width: parent.width; visible: Desk.notice !== ""; text: Desk.notice; wrapMode: Text.WordWrap; color: Theme.orange }
        }
    }
    component Action: Key {
        width: body.width; height: 36
        color: hovered ? Theme.raised : Theme.surface
        border.color: Theme.line; border.width: 1
    }
    component Caption: Label { font.pixelSize: 9; font.letterSpacing: 1; color: Theme.muted }
    Component {
        id: audioPage
        Column {
            spacing: 18
            Row {
                width: parent.width
                Label { width: parent.width - 85; text: Desk.sink?.description || "No output device"; wrapMode: Text.WordWrap; font.pixelSize: 11 }
                Label { text: String(Desk.volume).padStart(2,"0"); font.pixelSize: 32; color: Desk.muted ? Theme.faint : Theme.cream }
            }
            Controls.Slider {
                id: volumeSlider
                width: parent.width; height: 34; from: 0; to: 1; stepSize: 0.01
                value: Desk.volume / 100; enabled: !!Desk.audio
                onMoved: Desk.setVolume(value)
                background: Item {
                    x: volumeSlider.leftPadding; y: (volumeSlider.height - height)/2
                    width: volumeSlider.availableWidth; height: 18
                    Meter { count: 40; segmentWidth: 5; spacing: 3; value: volumeSlider.visualPosition; ink: Theme.cream; anchors.verticalCenter: parent.verticalCenter }
                }
                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: (volumeSlider.height-height)/2; width: 4; height: 24; radius: 1; color: Theme.orange
                }
                Accessible.name: "Output volume"
            }
            Row {
                spacing: 8
                Action { width: (body.width-8)/2; text: Desk.muted ? "Unmute" : "Mute"; onClicked: Desk.mute() }
                Action { width: (body.width-8)/2; text: "Audio settings ↗"; onClicked: Desk.launch(["pavucontrol"]) }
            }
            Caption { text: "OUTPUT / PIPEWIRE" }
        }
    }
    Component {
        id: networkPage
        Column {
            spacing: 13
            Row {
                spacing: 12
                Label { text: Desk.wired ? "󰈀" : "󰤨"; font.pixelSize: 30; color: Desk.connected ? Theme.cream : Theme.faint }
                Column { spacing: 4; Label { width: body.width - 52; text: Desk.networkName; font.pixelSize: 13 } Caption { text: Desk.connected ? "CONNECTED" : "DISCONNECTED" } }
            }
            Action { text: "Wi-Fi                              " + (Networking.wifiEnabled ? "ON" : "OFF"); onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
            Caption { text: "SAVED / NEARBY" }
            Repeater {
                model: Desk.wifi ? Desk.wifi.networks.values.slice().sort((a,b) => Number(b.connected)-Number(a.connected) || b.signalStrength-a.signalStrength).slice(0,5) : []
                delegate: Action {
                    required property var modelData
                    text: (modelData.connected ? "● " : "○ ") + modelData.name + (modelData.known ? "" : " ↗")
                    ink: modelData.connected ? Theme.cream : Theme.muted
                    onClicked: {
                        if (modelData.connected) return;
                        if (modelData.known) { modelData.connect(); Desk.notice = "Connecting to " + modelData.name + "…"; }
                        else Desk.launch(["serpantinum", "msg", "toggle", "network"]);
                    }
                    Connections {
                        target: modelData
                        function onConnectionFailed(reason) { Desk.notice = "Connection failed: " + ConnectionFailReason.toString(reason); }
                        function onConnectedChanged() { if (modelData.connected) Desk.notice = ""; }
                    }
                }
            }
            Action { text: "Network settings ↗"; onClicked: Desk.launch(["nm-connection-editor"]) }
        }
    }
    Component {
        id: bluetoothPage
        Column {
            spacing: 14
            Action { text: Desk.adapter ? "Bluetooth                          " + (Desk.adapter.enabled ? "ON" : "OFF") : "No Bluetooth adapter"; enabled: !!Desk.adapter; onClicked: Desk.adapter.enabled = !Desk.adapter.enabled }
            Repeater {
                model: Bluetooth.devices.values.filter(d => d.paired || d.connected).slice(0,6)
                delegate: Action {
                    required property var modelData
                    text: (modelData.connected ? "● " : "○ ") + modelData.name
                    onClicked: Desk.launch(["blueman-manager"])
                }
            }
            Action { text: "Pair & manage devices ↗"; onClicked: Desk.launch(["blueman-manager"]) }
        }
    }
    Component {
        id: calendarPage
        Column {
            id: cal
            property date month: new Date(Desk.now.getFullYear(), Desk.now.getMonth(), 1)
            readonly property int offset: (month.getDay()+6)%7
            spacing: 14
            Row {
                width: parent.width
                Key { text: "←"; width: 34; onClicked: cal.month = new Date(cal.month.getFullYear(), cal.month.getMonth()-1, 1) }
                Label { width: body.width-68; horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDateTime(cal.month,"MMMM yyyy"); color: Theme.cream }
                Key { text: "→"; width: 34; onClicked: cal.month = new Date(cal.month.getFullYear(), cal.month.getMonth()+1, 1) }
            }
            Grid {
                columns: 7; spacing: 4
                Repeater { model: ["M","T","W","T","F","S","S"]; Label { required property string modelData; text: modelData; width: (body.width-24)/7; horizontalAlignment: Text.AlignHCenter; color: Theme.faint; height: 19 } }
                Repeater {
                    model: 42
                    Rectangle {
                        required property int index
                        readonly property date day: new Date(cal.month.getFullYear(), cal.month.getMonth(), index-cal.offset+1)
                        readonly property bool today: day.toDateString() === Desk.now.toDateString()
                        width: (body.width-24)/7; height: 30; radius: 4
                        color: today ? Theme.cream : "transparent"
                        Label { anchors.centerIn: parent; text: parent.day.getDate(); color: parent.today ? Theme.base : parent.day.getMonth() === cal.month.getMonth() ? Theme.text : Theme.faint }
                        Rectangle { visible: parent.today; width: 4; height: 2; color: Theme.orange; anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 } }
                    }
                }
            }
            Caption { text: Qt.formatDateTime(Desk.now,"dddd, dd MMMM").toUpperCase() }
        }
    }
    Component {
        id: mediaPage
        Column {
            spacing: 17
            Label { width: parent.width; text: Desk.player?.trackTitle || "Nothing playing"; font.pixelSize: 19; wrapMode: Text.WordWrap }
            Label { width: parent.width; text: Desk.player?.trackArtist || "Media appears here when playback starts."; color: Theme.muted; wrapMode: Text.WordWrap }
            Row {
                spacing: 8
                Action { width: (body.width-16)/3; text: " previous"; enabled: Desk.player?.canGoPrevious ?? false; opacity: enabled ? 1 : 0.35; onClicked: Desk.player.previous() }
                Action { width: (body.width-16)/3; text: Desk.playing ? "pause" : "play"; enabled: Desk.player?.canTogglePlaying ?? false; opacity: enabled ? 1 : 0.35; onClicked: Desk.player.togglePlaying() }
                Action { width: (body.width-16)/3; text: "next "; enabled: Desk.player?.canGoNext ?? false; opacity: enabled ? 1 : 0.35; onClicked: Desk.player.next() }
            }
            Caption { text: Desk.player?.identity || "MPRIS" }
        }
    }
    Component {
        id: batteryPage
        Column {
            spacing: 19
            Label { text: Desk.hasBattery ? Desk.charge + "%" : "AC"; font.pixelSize: 56; font.weight: Font.Light; color: Theme.cream }
            Meter { count: 40; segmentWidth: 5; value: Desk.charge/100; ink: Desk.charge < 20 ? Theme.orange : Theme.cream }
            Caption { text: Desk.hasBattery ? UPowerDeviceState.toString(Desk.battery.state).toUpperCase() : "EXTERNAL POWER" }
            Label {
                text: Desk.battery?.state === UPowerDeviceState.Discharging && Desk.battery.timeToEmpty > 0 && Desk.battery.timeToEmpty < 259200
                    ? Math.floor(Desk.battery.timeToEmpty/3600) + "h " + Math.floor(Desk.battery.timeToEmpty%3600/60) + "m remaining"
                    : Desk.battery?.state === UPowerDeviceState.Charging && Desk.battery.timeToFull > 0 && Desk.battery.timeToFull < 259200
                    ? Math.ceil(Desk.battery.timeToFull/60) + "m until full" : ""
                visible: text !== ""
                color: Theme.muted
            }
        }
    }
    Component {
        id: sessionPage
        Column {
            spacing: 12
            Label { text: "Graphical Hyprland\nOperating System Toolkit"; font.pixelSize: 12; lineHeight: 1.5; color: Theme.cream }
            Caption { text: "TOP BAR / 0.1" }
            Action { text: "Launcher                          ↗"; onClicked: Desk.legacy("launcher") }
            Action { text: "Desktop settings                  ↗"; onClicked: Desk.legacy("guide") }
            Action { text: "Lock session                      󰌾"; onClicked: Desk.launch(["serpantinum", "lock"]) }
        }
    }
}
