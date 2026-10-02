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
        x: 19; y: 9; width: parent.width - 38; height: 46; radius: Theme.outerRadius
        Row {
            id: left
            x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 13
            Key {
                id: identity
                width: 42; height: 32
                hint: "Open controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                Row {
                    anchors.centerIn: parent; spacing: 10
                    SvgIcon { width: 20; height: 20; name:"menu" }
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
                    SvgIcon { width: 15; height: 15; name: Desk.playing ? "pause" : "play"; opacity:Desk.playing?1:.5; anchors.verticalCenter: parent.verticalCenter }
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
            width: bar.width > 1400 ? 230 : 130; height: 36
            anchors.centerIn: parent
            hint: "Calendar"
            onClicked: bar.open("calendar", this)
            Row {
                anchors.centerIn: parent; spacing: 11
                SvgIcon { width: 22; height: 22; name:"calendar"; anchors.verticalCenter:parent.verticalCenter }
                Label { text: Qt.formatDateTime(Desk.now, "HH:mm"); font.pixelSize: 24; font.weight: Font.Normal }
                Rectangle { visible: bar.width > 1400; width: 1; height: 29; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    visible: bar.width > 1400; spacing: 1; anchors.verticalCenter: parent.verticalCenter
                    Label { text: Qt.formatDateTime(Desk.now, "MM.dd"); font.pixelSize: 12 }
                    Row { spacing:4
                        SvgIcon { width:13;height:13;name:Desk.weatherSummary.condition==="clear"?"brightness":Desk.weatherSummary.condition==="unknown"?"cloud":Desk.weatherSummary.condition }
                        Label { text:typeof Desk.weatherSummary.temperature==="number"?Math.round(Desk.weatherSummary.temperature)+"°":"—";font.pixelSize:11;color:Theme.muted }
                    }
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
                id: sound
                width: 112; height: 32
                hint: "Audio · scroll for volume · right-click to mute"
                onClicked: bar.open("audio", this)
                onSecondaryClicked: Desk.mute()
                onScrolled: delta => Desk.setVolume((Desk.volume + (delta > 0 ? 2 : -2)) / 100)
                Row {
                    anchors.centerIn: parent; spacing: 8
                    SvgIcon { width: 16; height: 16; name: Desk.muted?"mute":"volume"; opacity: Desk.muted?.45:1; anchors.verticalCenter: parent.verticalCenter }
                    Meter { count: 7; value: Desk.muted ? 0 : Desk.volume / 100; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: Desk.volume; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Key {
                id: net
                width: 32
                ink: Desk.connected ? Theme.text : Theme.faint
                hint: Desk.networkName
                onClicked: Desk.toggleSidebar(bar.screenName)
                Row {
                    anchors.centerIn: parent
                    spacing: 9
                    SvgIcon { width: 16; height: 16; name: Desk.wired ? "ethernet" : "wifi"; opacity:Desk.connected?1:.45 }
                }
            }
            Key {
                width: 28
                ink: Desk.adapter?.enabled ? Theme.text : Theme.faint
                hint: "Bluetooth"
                onClicked: Desk.toggleSidebar(bar.screenName)
                SvgIcon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    name: "bluetooth"
                    opacity: Desk.adapter?.enabled ? 1 : .4
                }
            }
            Rule { visible: Desk.hasBattery }
            Key {
                visible: Desk.hasBattery
                width: bar.width > 1400 ? 78 : 65; height: 32
                hint: "Battery"
                onClicked: Desk.toggleSidebar(bar.screenName)
                Row {
                    anchors.centerIn: parent; spacing: 9
                    SvgIcon { visible: bar.width > 1400; width: 16; height: 16; name: "battery"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: Desk.charge + "%"; font.pixelSize: 10 }
                }
            }
            Key {
                width: 27; hint: "Session"
                onClicked: bar.open("session", this)
                SvgIcon { anchors.centerIn: parent; width: 16; height: 16; name: "power" }
            }
        }
    }
}
