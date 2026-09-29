import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
    id: bar
    property var monitor: null
    property var trayWindow: null
    property string screenName: ""
    property bool previewMode: false
    implicitHeight: 48
    function open(name, item) {
        const center = item.mapToItem(bar, item.width / 2, 0).x;
        Desk.toggle(name, screenName, Math.max(6, Math.min(width - 398, center - 196)), center);
    }
    Material {
        id: rail
        x: 6; y: 4; width: parent.width - 12; height: 40; radius: 6
        Row {
            id: left
            x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 13
            Key {
                id: identity
                width: 102; height: 32
                hint: "ghOSt · session"
                onClicked: bar.open("session", this)
                Row {
                    anchors.centerIn: parent; spacing: 10
                    BrandMark { width: 23; height: 23; ink: Theme.text }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: "ghOSt"; font.pixelSize: 13; font.letterSpacing: 0.8 }
                }
            }
            Rule {}
            Workspaces { monitor: bar.monitor }
            Rule { visible: bar.width > 1250 }
            Key {
                id: media
                visible: bar.width > 1250
                width: Math.min(235, Math.max(135, bar.width / 7.8)); height: 32
                hint: "Media controls"
                onClicked: bar.open("media", this)
                onSecondaryClicked: { if (Desk.player?.canTogglePlaying) Desk.player.togglePlaying(); }
                Row {
                    x: 7; anchors.verticalCenter: parent.verticalCenter; spacing: 9
                    Icon { width: 15; height: 15; name: Desk.playing ? "pause" : "play"; ink: Desk.playing ? Theme.text : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                    Label { width: media.width - 44; text: bar.previewMode ? "MEDIA" : Desk.player?.trackTitle || "NO PLAYBACK"; color: Desk.player ? Theme.text : Theme.faint; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 10 }
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 7 }
                    height: 1; color: Theme.line
                    Rectangle { width: parent.width * (Desk.playing ? 1 : 0); height: 1; color: Theme.blue; Behavior on width { NumberAnimation { duration: 220 } } }
                }
            }
        }
        Key {
            id: time
            width: bar.width > 1400 ? 208 : 110; height: 36
            anchors.centerIn: parent
            hint: "Calendar"
            onClicked: bar.open("calendar", this)
            Row {
                anchors.centerIn: parent; spacing: 11
                Label { text: Qt.formatDateTime(Desk.now, "HH:mm"); font.pixelSize: 19; font.weight: Font.Normal }
                Column {
                    spacing: 2; anchors.verticalCenter: parent.verticalCenter
                    Label { text: Qt.formatDateTime(Desk.now, "ss"); color: Theme.text; font.pixelSize: 9 }
                    Rectangle { width: 12; height: 1; color: Theme.line }
                }
                Rectangle { visible: bar.width > 1400; width: 1; height: 19; color: Theme.line; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    visible: bar.width > 1400; spacing: 1; anchors.verticalCenter: parent.verticalCenter
                    Label { text: Qt.formatDateTime(Desk.now, "ddd").toUpperCase(); font.pixelSize: 9; color: Theme.muted }
                    Label { text: Qt.formatDateTime(Desk.now, "dd MMM").toUpperCase(); font.pixelSize: 9 }
                }
            }
        }
        Row {
            id: right
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: bar.width > 1450 ? 10 : 4
            Row {
                anchors.verticalCenter: parent.verticalCenter; spacing: 2
                Repeater {
                    model: bar.previewMode ? [] : SystemTray.items
                    delegate: Key {
                        id: trayButton
                        required property var modelData
                        width: 27; height: 30
                        hint: modelData.tooltipTitle || modelData.title || modelData.id
                        IconImage { anchors.centerIn: parent; implicitSize: 15; source: trayButton.modelData.icon }
                        onClicked: { if (modelData.onlyMenu) modelData.display(bar.trayWindow, mapToItem(rail,0,0).x, 44); else modelData.activate(); }
                        onSecondaryClicked: modelData.display(bar.trayWindow, mapToItem(rail,0,0).x, 44)
                        onScrolled: delta => modelData.scroll(delta, false)
                    }
                }
            }
            Rule { visible: !bar.previewMode && SystemTray.items.values.length > 0 }
            Key {
                id: net
                width: bar.width > 1450 ? 80 : 32
                ink: Desk.connected ? Theme.text : Theme.faint
                hint: Desk.networkName
                onClicked: bar.open("network", this)
                Row {
                    anchors.centerIn: parent
                    spacing: 9
                    Icon { width: 16; height: 16; name: Desk.wired ? "network" : "wifi"; ink: net.ink }
                    Label { visible: bar.width > 1450; anchors.verticalCenter: parent.verticalCenter; text: Desk.wired ? "ETH" : Desk.connected ? "WI-FI" : "OFF"; color: net.ink; font.pixelSize: 10 }
                }
            }
            Key {
                width: 28
                ink: Desk.adapter?.enabled ? Theme.text : Theme.faint
                hint: "Bluetooth"
                onClicked: bar.open("bluetooth", this)
                Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    name: "bluetooth"
                    ink: parent.ink
                }
            }
            Rule {}
            Key {
                id: sound
                width: 112; height: 32
                hint: "Audio · scroll for volume · right-click to mute"
                onClicked: bar.open("audio", this)
                onSecondaryClicked: Desk.mute()
                onScrolled: delta => Desk.setVolume((Desk.volume + (delta > 0 ? 2 : -2)) / 100)
                Row {
                    anchors.centerIn: parent; spacing: 8
                    Icon { width: 16; height: 16; name: "volume"; ink: Desk.muted ? Theme.faint : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    Meter { count: 7; value: Desk.muted ? 0 : Desk.volume / 100; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: Desk.volume; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Rule { visible: Desk.hasBattery }
            Key {
                visible: Desk.hasBattery
                width: bar.width > 1400 ? 112 : 65; height: 32
                hint: "Battery"
                onClicked: bar.open("battery", this)
                Row {
                    anchors.centerIn: parent; spacing: 9
                    Icon { visible: bar.width > 1400; width: 16; height: 16; name: "battery"; ink: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: Desk.charge + "%"; font.pixelSize: 10 }
                }
            }
            Key {
                width: 27; hint: "Session"
                onClicked: bar.open("session", this)
                Icon { anchors.centerIn: parent; width: 16; height: 16; name: "power"; ink: Theme.text }
            }
        }
    }
}
