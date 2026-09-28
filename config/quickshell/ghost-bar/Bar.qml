import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: 48
    exclusiveZone: 48
    color: "transparent"
    WlrLayershell.namespace: "ghost-bar"
    WlrLayershell.layer: WlrLayer.Top
    readonly property var monitor: Hyprland.monitorFor(screen)
    function open(name, item) {
        const point = item.mapToItem(rail, 0, 0);
        Desk.toggle(name, screen.name, Math.max(8, Math.min(width - 400, point.x + item.width / 2 - 190)));
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
                    Rectangle {
                        width: 23; height: 23; radius: 4; color: Theme.orange
                        Label { anchors.centerIn: parent; text: "g"; color: Theme.base; font.pixelSize: 20; font.weight: Font.Bold; anchors.verticalCenterOffset: -2 }
                    }
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
                    Label { text: Desk.playing ? "Ⅱ" : "▷"; color: Desk.playing ? Theme.orange : Theme.muted; font.pixelSize: 15 }
                    Label { width: media.width - 44; text: Desk.player?.trackTitle || "NO PLAYBACK"; color: Desk.player ? Theme.text : Theme.faint; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 10 }
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
                    Label { text: Qt.formatDateTime(Desk.now, "ss"); color: Theme.orange; font.pixelSize: 9 }
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
                    model: SystemTray.items
                    delegate: Key {
                        id: trayButton
                        required property var modelData
                        width: 27; height: 30
                        hint: modelData.tooltipTitle || modelData.title || modelData.id
                        IconImage { anchors.centerIn: parent; implicitSize: 15; source: trayButton.modelData.icon }
                        onClicked: { if (modelData.onlyMenu) modelData.display(bar, mapToItem(rail,0,0).x, 44); else modelData.activate(); }
                        onSecondaryClicked: modelData.display(bar, mapToItem(rail,0,0).x, 44)
                        onScrolled: delta => modelData.scroll(delta, false)
                    }
                }
            }
            Rule { visible: SystemTray.items.values.length > 0 }
            Key {
                id: net
                text: (Desk.wired ? "󰈀" : "󰤨") + (bar.width > 1450 ? (Desk.wired ? "  ETH" : Desk.connected ? "  WI-FI" : "  OFF") : "")
                ink: Desk.connected ? Theme.text : Theme.faint
                hint: Desk.networkName
                onClicked: bar.open("network", this)
            }
            Key {
                text: "󰂯"; ink: Desk.adapter?.enabled ? Theme.text : Theme.faint
                hint: "Bluetooth"
                onClicked: bar.open("bluetooth", this)
            }
            Rule {}
            Key {
                id: sound
                width: hovered || Desk.panel === "audio" ? 112 : 88; height: 32
                Behavior on width { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
                hint: "Audio · scroll for volume · right-click to mute"
                onClicked: bar.open("audio", this)
                onSecondaryClicked: Desk.mute()
                onScrolled: delta => Desk.setVolume((Desk.volume + (delta > 0 ? 2 : -2)) / 100)
                Row {
                    anchors.centerIn: parent; spacing: 8
                    Label { text: Desk.muted ? "󰝟" : "󰕾"; font.pixelSize: 15; color: Desk.muted ? Theme.faint : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    Meter { count: 7; value: Desk.muted ? 0 : Desk.volume / 100; anchors.verticalCenter: parent.verticalCenter }
                    Label { visible: sound.width > 108; text: Desk.volume; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
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
                    Meter { visible: bar.width > 1400; count: 7; value: Desk.charge / 100; ink: Desk.charge <= 20 ? Theme.orange : Theme.cream; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: Desk.charge + "%"; font.pixelSize: 10 }
                }
            }
            Key {
                width: 27; text: "⏻"; hint: "Session"
                onClicked: bar.open("session", this)
            }
        }
    }
}
