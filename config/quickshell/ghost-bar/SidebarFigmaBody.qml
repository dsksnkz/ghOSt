import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import "Corners.js" as Corners

Item {
    id: sidebar
    property var screen
    property bool previewMode: false
    property bool previewLongNames: false
    property bool opened: true
    property real reveal: 1
    readonly property bool dnd: Notifications.dnd
    readonly property bool notificationsAvailable: Notifications.ready
    readonly property int notificationCount: Notifications.count
    property var brightnessPercent: null
    property var entranceOrder: [0, 1, 2, 3, 4, 5]
    property real entranceTime: 900
    function beginEntrance() {
        let items = [0, 1, 2, 3, 4, 5];
        for (let i = 5; i > 0; i--) {
            let j = Math.floor(Math.random() * (i + 1));
            [items[i], items[j]] = [items[j], items[i]];
        }
        if (items.join() === entranceOrder.join())
            items.push(items.shift());
        entranceOrder = items;
        entranceTime = Theme.reducedMotion ? 900 : 0;
        if (!Theme.reducedMotion)
            itemEntrance.restart();
    }
    function itemProgress(index) {
        return Theme.reducedMotion ? 1 : Math.max(0, Math.min(1, (entranceTime - 100 - entranceOrder.indexOf(index) * 65) / 220));
    }
    NumberAnimation {
        id: itemEntrance
        target: sidebar
        property: "entranceTime"
        from: 0
        to: 900
        duration: 900
    }
    signal closeRequested
    // The native window focuses this root, not necessarily the scaled child.
    focus: opened
    Keys.onEscapePressed: closeRequested()
    function refresh() {
        if (previewMode || !opened)
            return;
        if (screen?.name?.startsWith("eDP-"))
            brightnessQuery.running = true;
    }
    onOpenedChanged: {
        if (opened)
            beginEntrance();
        else
            itemEntrance.stop();
        refresh();
    }
    Component.onCompleted: {
        if (opened)
            beginEntrance();
        refresh();
    }
    Process {
        id: brightnessQuery
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(text.trim().split(",")[3]?.replace("%", ""));
                sidebar.brightnessPercent = isFinite(value) ? value : null;
            }
        }
    }
    Timer {
        interval: 3000
        repeat: true
        running: sidebar.opened && !sidebar.previewMode
        onTriggered: sidebar.refresh()
    }

    // The Figma artboard is 1920 × 1080. This panel occupies x=0..354;
    // its nested controls use the measured artboard coordinates minus y=146.
    readonly property real designWidth: 354
    readonly property real designHeight: 790
    readonly property real fit: Math.min(width / designWidth, height / designHeight)
    readonly property real outerRadius: Theme.outerRadius
    readonly property real cardRadius: 15
    readonly property real itemRadius: 15
    readonly property real cardInset: 4
    readonly property real innerRadius: Math.max(0, cardRadius - cardInset)

    component SliderFill: Canvas {
        property real fraction: 0
        anchors.fill: parent
        onFractionChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"), w = width - 1, h = height - 1, r = Math.min(sidebar.itemRadius - .5, w / 2, h / 2);
            c.reset();
            c.clearRect(0, 0, width, height);
            c.translate(.5, .5);
            Corners.trace(c, w, h, r, 0);
            c.clip();
            c.fillStyle = "#cecece";
            c.fillRect(0, 0, w * fraction, h);
        }
    }

    Item {
        id: surface
        width: sidebar.designWidth
        height: sidebar.designHeight
        scale: sidebar.fit
        transformOrigin: Item.TopLeft
        transform: Translate {
            x: -(sidebar.designWidth + 8) * (1 - sidebar.reveal)
        }
        G2Surface {
            x: -37
            y: 0
            width: 391
            height: 790
            radius: sidebar.outerRadius
            gradient: Gradient {
                GradientStop {
                    position: .12
                    color: "#181818"
                }
                GradientStop {
                    position: 1
                    color: "#1b1b1b"
                }
            }
        }
        G2Surface {
            x: -39
            y: -2
            width: 395
            height: 794
            radius: sidebar.outerRadius + 2
            color: "transparent"
            border.color: "#5d5d5d"
            border.width: 2
        }
        focus: sidebar.opened
        Keys.onEscapePressed: sidebar.closeRequested()
        Canvas {
            x: 24
            y: 113
            width: 314
            height: 646
            opacity: .3
            onPaint: {
                const c = getContext("2d");
                c.reset();
                c.fillStyle = "#454545";
                for (let yy = 6; yy < height; yy += 24)
                    for (let xx = 7; xx < width; xx += 24)
                        c.fillRect(xx, yy, 3, 3);
            }
        }

        // Figma: time and controls share one quiet header. Status sits above
        // the buttons, rather than consuming a second full-width row.
        Label {
            x: 28
            y: 33
            width: 144
            height: 63
            opacity: sidebar.itemProgress(0)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(0))
            }
            text: sidebar.previewMode ? "09:21" : Qt.formatDateTime(Desk.now, "HH:mm")
            font.pixelSize: 48
            font.weight: Font.Normal
            color: "#ffffff"
        }
        Item {
            id: statusGroup
            anchors.right: parent.right
            anchors.rightMargin: 21
            y: 13
            width: 136
            height: 26
            opacity: sidebar.itemProgress(0)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(0))
            }
            SvgIcon {
                id: statusWifi
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                name: sidebar.previewMode ? "wifi" : Desk.wired ? "ethernet" : "wifi"
                opacity: sidebar.previewMode || Desk.connected ? 1 : .45
            }
            SvgIcon {
                id: statusBluetooth
                x: 32
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                name: "bluetooth"
                opacity: sidebar.previewMode || Desk.adapter?.enabled ? 1 : .45
            }
            Label {
                x: 64
                anchors.verticalCenter: parent.verticalCenter
                text: sidebar.previewMode ? "100%" : Desk.hasBattery ? Desk.charge + "%" : "AC"
                font.pixelSize: 14
                font.weight: Font.Bold
                width: 34
                height: 22
                verticalAlignment: Text.AlignVCenter
                color: "#ffffff"
            }
            SvgIcon {
                id: statusBattery
                x: 106
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 26
                name: "battery"
                visible: Desk.hasBattery || sidebar.previewMode
            }
        }
        Key {
            x: 192
            y: 46
            width: 37
            height: 37
            radius: sidebar.itemRadius
            color: "#d9d9d9"
            hint: "Power"
            opacity: sidebar.itemProgress(0)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(0))
            }
            onClicked: if (!sidebar.previewMode)
                Desk.toggle("session", sidebar.screen.name, Math.max(6, 192 * sidebar.fit))
            SvgIcon {
                anchors.centerIn: parent
                width: 22
                height: 22
                name: "power"
                black: true
            }
        }
        Key {
            x: 244
            y: 46
            width: 37
            height: 37
            radius: sidebar.itemRadius
            color: "#d9d9d9"
            hint: "Settings"
            opacity: sidebar.itemProgress(0)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(0))
            }
            onClicked: if (!sidebar.previewMode)
                Desk.openSettings(sidebar.screen.name)
            SvgIcon {
                anchors.centerIn: parent
                width: 23
                height: 23
                name: "settings"
                black: true
            }
        }
        Key {
            x: 296
            y: 46
            width: 37
            height: 37
            radius: sidebar.itemRadius
            color: "#d9d9d9"
            hint: sidebar.dnd ? "Disable do not disturb" : "Enable do not disturb"
            enabled: sidebar.previewMode || sidebar.notificationsAvailable
            opacity: sidebar.itemProgress(0)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(0))
            }
            onClicked: Notifications.setDnd(!sidebar.dnd)
            SvgIcon {
                anchors.centerIn: parent
                width: 22
                height: 22
                name: "notifications"
                black: true
            }
            G2Surface {
                visible: sidebar.dnd
                anchors.centerIn: parent
                width: 27
                height: 1.5
                rotation: -45
                color: "#111111"
            }
        }

        // Three visible layers: bordered housing, inset list well, and
        // the light control cap. Figma card: 144 × 222, gap 17.
        G2Surface {
            id: wifiHousing
            visible: Settings.widget("network")
            opacity: sidebar.itemProgress(1)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(1))
            }
            x: 28
            y: 120
            width: 144
            height: 222
            radius: sidebar.cardRadius
            color: "#262626"
            border.color: "#323232"
            border.width: 1
            G2Surface {
                x: 5
                y: 4
                width: 134
                height: 213
                radius: sidebar.innerRadius
                color: "#393939"
            }
            Key {
                x: 5
                y: 4
                width: 134
                height: 36
                radius: sidebar.innerRadius
                color: sidebar.previewMode || Networking.wifiEnabled ? "#cecece" : "#777777"
                hint: "Toggle Wi-Fi"
                ink: "#111111"
                onClicked: if (!sidebar.previewMode)
                    Networking.wifiEnabled = !Networking.wifiEnabled
                SvgIcon {
                    x: 10
                    y: 8
                    width: 20
                    height: 20
                    name: "wifi"
                    black: true
                }
                Label {
                    x: 39
                    y: 9
                    width: 34
                    height: 18
                    text: "Wlan"
                    color: "#000000"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
            }
            Flickable {
                x: 7
                y: 47
                width: parent.width - 14
                height: parent.height - 53
                layer.enabled: true
                contentHeight: wifiList.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: wifiList
                    width: parent.width
                    spacing: 5
                    Repeater {
                        model: sidebar.previewMode ? [
                            {
                                name: sidebar.previewLongNames ? "A very long wireless network name" : "Network 01",
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
                            height: 24
                            radius: sidebar.innerRadius
                            hint: modelData.name
                            onClicked: {
                                if (sidebar.previewMode || modelData.connected)
                                    return;
                                if (modelData.known)
                                    modelData.connect();
                                else
                                    Desk.launch(["nm-connection-editor"]);
                            }
                            SvgIcon {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 17
                                height: 17
                                name: "check"
                                visible: modelData.connected
                            }
                            FadeLabel {
                                x: 44
                                y: 6
                                width: 86
                                height: 17
                                text: modelData.name
                                font.pixelSize: 11
                                color: "#ffffff"
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
        G2Surface {
            id: btHousing
            visible: Settings.widget("bluetooth")
            opacity: sidebar.itemProgress(2)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(2))
            }
            x: 189
            y: 120
            width: 144
            height: 222
            radius: sidebar.cardRadius
            color: "#262626"
            border.color: "#323232"
            border.width: 1
            G2Surface {
                x: 5
                y: 4
                width: 134
                height: 213
                radius: sidebar.innerRadius
                color: "#393939"
            }
            Key {
                x: 5
                y: 4
                width: 134
                height: 36
                radius: sidebar.innerRadius
                color: sidebar.previewMode || Desk.adapter?.enabled ? "#cecece" : "#777777"
                hint: "Toggle Bluetooth"
                enabled: sidebar.previewMode || !!Desk.adapter
                onClicked: if (!sidebar.previewMode)
                    Desk.adapter.enabled = !Desk.adapter.enabled
                Row {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    SvgIcon {
                        width: 16
                        height: 16
                        name: "bluetooth"
                        black: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        text: "Bluetooth"
                        color: "#111111"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Flickable {
                x: 7
                y: 47
                width: parent.width - 14
                height: parent.height - 53
                layer.enabled: true
                contentHeight: btList.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: btList
                    width: parent.width
                    spacing: 5
                    Repeater {
                        model: sidebar.previewMode ? [
                            {
                                name: sidebar.previewLongNames ? "A very long Bluetooth device name" : "Mouse",
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
                            height: 24
                            radius: sidebar.innerRadius
                            hint: modelData.name
                            onClicked: if (!sidebar.previewMode)
                                Desk.launch(["blueman-manager"])
                            SvgIcon {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 17
                                height: 17
                                name: "check"
                                visible: modelData.connected
                            }
                            FadeLabel {
                                x: 44
                                y: 6
                                width: 86
                                height: 17
                                text: modelData.name
                                font.pixelSize: 11
                                color: "#ffffff"
                            }
                        }
                    }
                    Key {
                        width: btList.width
                        height: 24
                        radius: sidebar.innerRadius
                        text: "Manage devices"
                        hint: "Manage Bluetooth devices"
                        onClicked: if (!sidebar.previewMode)
                            Desk.launch(["blueman-manager"])
                    }
                }
            }
        }

        Controls.Slider {
            id: volume
            visible: Settings.widget("volume")
            opacity: sidebar.itemProgress(3)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(3))
            }
            x: 29
            y: 361
            width: 304
            height: 34
            padding: 0
            from: 0
            to: 1
            value: sidebar.previewMode ? .62 : Desk.volume / 100
            enabled: sidebar.previewMode || !!Desk.audio
            onMoved: if (!sidebar.previewMode)
                Desk.setVolume(value)
            Accessible.name: "Output volume"
            background: G2Surface {
                x: volume.leftPadding
                y: 0
                width: volume.availableWidth
                height: 34
                radius: sidebar.itemRadius
                color: "#262626"
                border.color: "#323232"
                clip: true
                SliderFill {
                    fraction: volume.visualPosition
                }
            }
            handle: SvgIcon {
                x: 11
                y: 9
                width: 16
                height: 16
                name: "volume"
                black: volume.visualPosition > .09
            }
        }
        Controls.Slider {
            id: brightness
            visible: Settings.widget("brightness")
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(4))
            }
            x: 29
            y: 415
            width: 304
            height: 34
            padding: 0
            from: 0
            to: 100
            value: sidebar.previewMode ? 75 : sidebar.brightnessPercent ?? 0
            enabled: sidebar.previewMode || sidebar.screen?.name?.startsWith("eDP-") && sidebar.brightnessPercent !== null
            opacity: sidebar.itemProgress(4) * (enabled ? 1 : .4)
            onMoved: if (!sidebar.previewMode)
                Quickshell.execDetached(["brightnessctl", "set", Math.round(value) + "%"])
            Accessible.name: "Display brightness"
            background: G2Surface {
                x: brightness.leftPadding
                y: 0
                width: brightness.availableWidth
                height: 34
                radius: sidebar.itemRadius
                color: "#262626"
                border.color: "#323232"
                clip: true
                SliderFill {
                    fraction: brightness.visualPosition
                }
            }
            handle: SvgIcon {
                x: 11
                y: 9
                width: 16
                height: 16
                name: "brightness"
                black: brightness.visualPosition > .09
            }
        }

        G2Surface {
            id: notificationFrame
            visible: Settings.widget("notifications")
            opacity: sidebar.itemProgress(5)
            transform: Translate {
                x: -24 * (1 - sidebar.itemProgress(5))
            }
            x: 29
            y: 470
            width: 304
            height: 284
            radius: sidebar.itemRadius
            color: "#262626"
            border.color: "#323232"
            clip: true
            Canvas {
                anchors.fill: parent
                opacity: .15
                onPaint: {
                    const c = getContext("2d");
                    c.clearRect(0, 0, width, height);
                    c.fillStyle = "#555555";
                    for (let yy = 7; yy < height; yy += 18)
                        for (let xx = 8; xx < width; xx += 18)
                            c.fillRect(xx, yy, 1, 1);
                }
            }
            NotificationList {
                x: 5
                y: 5
                width: parent.width - 10
                height: parent.height - (sidebar.notificationCount > 0 ? 34 : 10)
                previewMode: sidebar.previewMode
                textOnlyEmpty: true
            }
            Key {
                x: parent.width - 75
                y: parent.height - 27
                width: 68
                height: 22
                text: "Dismiss"
                fontSize: 9
                hint: "Dismiss notifications"
                visible: sidebar.notificationCount > 0
                enabled: sidebar.notificationsAvailable && sidebar.notificationCount > 0
                onClicked: Notifications.clear()
            }
        }
    }
}
