import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth

Item {
    id: sidebar
    property var screen
    property bool previewMode: false
    property bool settingsOpen: false
    property bool opened: true
    property real reveal: 1
    signal closeRequested
    G2Surface {
        id: content
        anchors.fill: parent
        anchors.margins: 1
        radius: Theme.outerRadius
        color: "#181818"
        border.color: "#555555"
        transform: Translate {
            x: -(sidebar.width + 16) * (1 - sidebar.reveal)
        }
        Keys.onEscapePressed: {
            if (sidebar.settingsOpen)
                sidebar.settingsOpen = false;
            else
                sidebar.closeRequested();
        }
        readonly property real pad: 20
        readonly property real inner: Math.max(0, Theme.outerRadius - 3)
        Flickable {
            id: sideScroll
            x: content.pad
            y: 24
            width: content.width - content.pad * 2
            height: content.height - 48
            contentHeight: sections.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: sections
                width: parent.width
                spacing: 17
                Row {
                    width: parent.width
                    height: 66
                    Label {
                        width: parent.width - 116
                        text: Qt.formatDateTime(Desk.now, "HH:mm")
                        font.pixelSize: 38
                        font.weight: Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Row {
                        width: 116
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter
                        Key {
                            width: 34
                            height: 34
                            radius: 17
                            color: "#dadada"
                            hint: "Settings"
                            onClicked: sidebar.settingsOpen = !sidebar.settingsOpen
                            SvgIcon {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                name: "settings"
                                black: true
                            }
                        }
                        Key {
                            width: 34
                            height: 34
                            radius: 17
                            color: "#dadada"
                            hint: "Notifications"
                            onClicked: sideScroll.contentY = Math.max(0, sideScroll.contentHeight - sideScroll.height)
                            SvgIcon {
                                anchors.centerIn: parent
                                width: 21
                                height: 21
                                name: "notifications"
                                black: true
                            }
                        }
                    }
                }
                Row {
                    width: parent.width
                    height: 20
                    spacing: 7
                    SvgIcon {
                        width: 13
                        height: 13
                        name: Desk.wired ? "ethernet" : "wifi"
                    }
                    Label {
                        text: sidebar.previewMode ? "Wi-Fi" : Desk.networkName
                        font.pixelSize: 10
                        color: Theme.muted
                        width: parent.width - 101
                        elide: Text.ElideRight
                    }
                    SvgIcon {
                        width: 13
                        height: 13
                        name: "bluetooth"
                        opacity: Desk.adapter?.enabled ? 1 : .35
                    }
                    Label {
                        text: sidebar.previewMode ? "100%" : Desk.hasBattery ? Desk.charge + "%" : "AC"
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }
                Row {
                    width: parent.width
                    height: 236
                    spacing: 8
                    Column {
                        width: (parent.width - 8) / 2
                        spacing: 5
                        Key {
                            width: parent.width
                            height: 34
                            radius: content.inner
                            color: sidebar.previewMode || Networking.wifiEnabled ? "#dddddd" : "#555555"
                            ink: Theme.base
                            hint: "Toggle Wi-Fi"
                            onClicked: if (!sidebar.previewMode)
                                Networking.wifiEnabled = !Networking.wifiEnabled
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                SvgIcon {
                                    width: 17
                                    height: 17
                                    name: "wifi"
                                    black: true
                                }
                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "WLAN"
                                    font.pixelSize: 12
                                    color: Theme.base
                                }
                            }
                        }
                        G2Surface {
                            width: parent.width
                            height: 195
                            radius: content.inner
                            color: "#303030"
                            clip: true
                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 5
                                contentHeight: wifiList.height
                                boundsBehavior: Flickable.StopAtBounds
                                Column {
                                    id: wifiList
                                    width: parent.width
                                    spacing: 3
                                    Repeater {
                                        model: sidebar.previewMode ? [
                                            {
                                                name: "Network 01",
                                                connected: true,
                                                known: true
                                            },
                                            {
                                                name: "Studio",
                                                connected: false,
                                                known: true
                                            },
                                            {
                                                name: "Guest",
                                                connected: false,
                                                known: false
                                            }
                                        ] : Desk.wifi?.networks.values?.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength).slice(0, 12) ?? []
                                        Key {
                                            required property var modelData
                                            width: wifiList.width
                                            height: 25
                                            radius: content.inner
                                            hint: modelData.name
                                            onClicked: {
                                                if (sidebar.previewMode || modelData.connected)
                                                    return;
                                                if (modelData.known)
                                                    modelData.connect();
                                                else
                                                    Desk.launch(["nm-connection-editor"]);
                                            }
                                            Row {
                                                x: 5
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 4
                                                SvgIcon {
                                                    width: 13
                                                    height: 13
                                                    name: modelData.connected ? "check" : "wifi"
                                                    opacity: modelData.connected ? 1 : .6
                                                }
                                                Label {
                                                    text: modelData.name
                                                    width: wifiList.width - 25
                                                    font.pixelSize: 9
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }
                                    }
                                    Label {
                                        visible: !sidebar.previewMode && (!Desk.wifi || Desk.wifi.networks.values.length === 0)
                                        text: "No networks"
                                        font.pixelSize: 10
                                        color: Theme.muted
                                    }
                                }
                            }
                        }
                    }
                    Column {
                        width: (parent.width - 8) / 2
                        spacing: 5
                        Key {
                            width: parent.width
                            height: 34
                            radius: content.inner
                            color: sidebar.previewMode || Desk.adapter?.enabled ? "#dddddd" : "#555555"
                            hint: "Toggle Bluetooth"
                            enabled: sidebar.previewMode || !!Desk.adapter
                            onClicked: if (!sidebar.previewMode)
                                Desk.adapter.enabled = !Desk.adapter.enabled
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                SvgIcon {
                                    width: 17
                                    height: 17
                                    name: "bluetooth"
                                    black: true
                                }
                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Bluetooth"
                                    font.pixelSize: 12
                                    color: Theme.base
                                }
                            }
                        }
                        G2Surface {
                            width: parent.width
                            height: 195
                            radius: content.inner
                            color: "#303030"
                            clip: true
                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 5
                                contentHeight: btList.height
                                boundsBehavior: Flickable.StopAtBounds
                                Column {
                                    id: btList
                                    width: parent.width
                                    spacing: 3
                                    Repeater {
                                        model: sidebar.previewMode ? [
                                            {
                                                name: "Mouse",
                                                connected: true
                                            },
                                            {
                                                name: "Keyboard",
                                                connected: true
                                            }
                                        ] : Bluetooth.devices.values.filter(d => d.paired || d.connected).slice(0, 12)
                                        Key {
                                            required property var modelData
                                            width: btList.width
                                            height: 25
                                            radius: content.inner
                                            hint: modelData.name
                                            onClicked: if (!sidebar.previewMode)
                                                Desk.launch(["blueman-manager"])
                                            Row {
                                                x: 5
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 4
                                                SvgIcon {
                                                    width: 13
                                                    height: 13
                                                    name: modelData.connected ? "check" : "bluetooth"
                                                    opacity: modelData.connected ? 1 : .6
                                                }
                                                Label {
                                                    text: modelData.name
                                                    width: btList.width - 25
                                                    font.pixelSize: 9
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }
                                    }
                                    Key {
                                        width: btList.width
                                        height: 28
                                        text: "Manage devices"
                                        hint: "Manage Bluetooth devices"
                                        onClicked: Desk.launch(["blueman-manager"])
                                    }
                                }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width
                    spacing: 10
                    Label {
                        text: "VOLUME"
                        font.pixelSize: 9
                        color: Theme.muted
                        opacity: .8
                    }
                    Controls.Slider {
                        id: volume
                        width: parent.width
                        height: 26
                        from: 0
                        to: 1
                        value: sidebar.previewMode ? .62 : Desk.volume / 100
                        enabled: sidebar.previewMode || !!Desk.audio
                        onMoved: if (!sidebar.previewMode)
                            Desk.setVolume(value)
                        Accessible.name: "Output volume"
                        background: G2Surface {
                            x: volume.leftPadding
                            y: (volume.height - height) / 2
                            width: volume.availableWidth
                            height: 22
                            radius: content.inner
                            color: "#292929"
                            border.color: Theme.line
                            G2Surface {
                                width: volume.visualPosition * parent.width
                                height: parent.height
                                radius: Math.min(content.inner, width / 2)
                                color: "#d9d9d9"
                            }
                        }
                        handle: SvgIcon {
                            x: volume.leftPadding + volume.visualPosition * (volume.availableWidth - width)
                            y: (volume.height - height) / 2
                            width: 18
                            height: 18
                            name: "volume"
                            black: volume.visualPosition > .06
                        }
                    }
                    Label {
                        text: sidebar.previewMode || sidebar.screen.name.startsWith("eDP-") ? "BRIGHTNESS" : "MONITOR BRIGHTNESS UNAVAILABLE"
                        font.pixelSize: 9
                        color: Theme.muted
                        opacity: .8
                    }
                    Controls.Slider {
                        id: brightness
                        width: parent.width
                        height: 26
                        from: 0
                        to: 100
                        value: sidebar.previewMode ? 75 : 50
                        enabled: sidebar.previewMode || sidebar.screen.name.startsWith("eDP-")
                        opacity: enabled ? 1 : .35
                        onMoved: if (!sidebar.previewMode)
                            Quickshell.execDetached(["brightnessctl", "set", Math.round(value) + "%"])
                        Accessible.name: "Display brightness"
                        background: G2Surface {
                            x: brightness.leftPadding
                            y: (brightness.height - height) / 2
                            width: brightness.availableWidth
                            height: 22
                            radius: content.inner
                            color: "#292929"
                            border.color: Theme.line
                            G2Surface {
                                width: brightness.visualPosition * parent.width
                                height: parent.height
                                radius: Math.min(content.inner, width / 2)
                                color: "#d9d9d9"
                            }
                        }
                        handle: SvgIcon {
                            x: brightness.leftPadding + brightness.visualPosition * (brightness.availableWidth - width)
                            y: (brightness.height - height) / 2
                            width: 18
                            height: 18
                            name: "brightness"
                            black: brightness.visualPosition > .06
                        }
                    }
                }
                G2Surface {
                    width: parent.width
                    height: 1
                    color: Theme.line
                }
                Column {
                    width: parent.width
                    spacing: 10
                    Label {
                        text: "NOTIFICATIONS"
                        font.pixelSize: 9
                        color: Theme.muted
                    }
                    Key {
                        width: parent.width
                        height: 64
                        radius: content.inner
                        color: "#222222"
                        border.color: Theme.line
                        border.width: 1
                        hint: "Notification service unavailable"
                        enabled: false
                        Row {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 11
                            SvgIcon {
                                width: 26
                                height: 26
                                name: "notifications"
                            }
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: sidebar.previewMode ? "No notifications" : "Notifications unavailable"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
        G2Surface {
            anchors.fill: parent
            anchors.margins: 12
            radius: Theme.innerRadius(4)
            visible: sidebar.settingsOpen
            color: Theme.surface
            border.color: Theme.line
            Column {
                x: 18
                y: 20
                width: parent.width - 36
                spacing: 16
                Row {
                    width: parent.width
                    Label {
                        width: parent.width - 34
                        text: "SETTINGS"
                        font.pixelSize: 13
                    }
                    Key {
                        width: 30
                        height: 28
                        text: "×"
                        hint: "Close settings"
                        onClicked: sidebar.settingsOpen = false
                    }
                }
                Key {
                    width: parent.width
                    height: 36
                    text: "Reduced motion  " + (Theme.reducedMotion ? "On" : "Off")
                    hint: "Toggle reduced motion"
                    onClicked: Theme.reducedMotion = !Theme.reducedMotion
                }
                Key {
                    width: parent.width
                    height: 36
                    text: "Network settings"
                    hint: "Open network settings"
                    onClicked: if (!sidebar.previewMode)
                        Desk.launch(["nm-connection-editor"])
                }
                Key {
                    width: parent.width
                    height: 36
                    text: "Bluetooth settings"
                    hint: "Open Bluetooth settings"
                    onClicked: Desk.launch(["blueman-manager"])
                }
            }
        }
    }
}
