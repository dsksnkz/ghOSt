import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth menu under the top bar icon. Connected devices show their battery
// and a Disconnect bar; AirPods also show each bud, the case and their listening
// mode. Other paired devices connect on a click; nearby devices are found while
// the menu is open. Device options open on a second page that slides in.
Item {
    id: menu
    property bool previewMode: false
    // False while the popup closes; scanning stops and the lists hold still.
    property bool active: true
    property var selected: null             // Device shown on the options page.
    readonly property var adapter: Desk.adapter
    readonly property bool enabled: !!adapter?.enabled
    readonly property var paired: Bluetooth.devices.values.filter(d => d.paired || d.connected)
        .sort((a, b) => Number(b.connected) - Number(a.connected) || a.name.localeCompare(b.name))
    readonly property var liveFound: Bluetooth.devices.values.filter(d => !d.paired && !d.connected && d.deviceName)
        .sort((a, b) => a.name.localeCompare(b.name)).slice(0, 8)
    property var found: []
    Binding on found {
        value: menu.liveFound
        when: menu.active
        restoreMode: Binding.RestoreNone
    }
    // AirPods status comes from the shared link in AirPods.qml.
    readonly property var headset: AirPods.device
    readonly property var pods: AirPods.state
    readonly property bool podsReady: AirPods.ready
    width: Theme.menuWidth
    implicitHeight: 590

    function percent(value) {
        return Math.round(value * 100) + "%";
    }
    function batteryOf(device) {
        if (device === headset && podsReady) {
            const parts = ["left", "right", "headset"].map(key => pods.battery?.[key]?.level).filter(v => v !== undefined);
            if (parts.length)
                return Math.min(...parts) + "%";
        }
        return device.batteryAvailable ? percent(device.battery) : "";
    }
    function subtitle(device) {
        const model = device === headset && podsReady && pods.model ? pods.model : device.deviceName && device.deviceName !== device.name ? device.deviceName : "";
        return model ? "  -  " + model : "";
    }
    function stateText(device) {
        if (device.pairing)
            return "Pairing…";
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        return device.connected ? "" : "Disconnected";
    }
    function activate(device) {
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else {
            // Trusted devices reconnect by themselves next time.
            device.trusted = true;
            device.pair();
        }
    }
    // Look for nearby devices only while the menu is open; scanning costs power.
    Binding {
        target: menu.adapter
        property: "discovering"
        value: menu.active && menu.enabled
        when: !!menu.adapter && !menu.previewMode
        restoreMode: Binding.RestoreNone
    }
    onActiveChanged: if (!active)
        selected = null

    component Caption: Label {
        font.pixelSize: 11
        color: Theme.muted
    }
    // Device kind drawn from BlueZ's icon name: speaker, headphones, phone, computer, input.
    component Glyph: Item {
        property string kind: ""
        width: 30
        height: 30
        readonly property string family: kind.startsWith("audio") ? "speaker"
            : kind.startsWith("phone") ? "phone" : kind.startsWith("computer") ? "computer"
            : kind.startsWith("input-keyboard") ? "keyboard" : kind.startsWith("input-mouse") ? "mouse" : "bluetooth"
        // Speaker: a box with a cone.
        Rectangle {
            visible: parent.family === "speaker"
            anchors.centerIn: parent
            width: 22
            height: 28
            radius: 4
            color: "transparent"
            border.width: 1.5
            border.color: Theme.text
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 12
                width: 10
                height: 10
                radius: 5
                color: "transparent"
                border.width: 1.5
                border.color: Theme.text
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 5
                width: 3
                height: 3
                radius: 1.5
                color: Theme.text
            }
        }
        // Phone: a handset.
        LineGlyph {
            visible: parent.family === "phone"
            anchors.centerIn: parent
            width: 24
            height: 23
            kind: "phone"
            ink: "#ffffff"
        }
        // Headphones and AirPods: two buds.
        Row {
            visible: parent.family === "headphones"
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: 2
                Item {
                    width: 9
                    height: 24
                    Rectangle {
                        width: 9
                        height: 11
                        radius: 4.5
                        color: "transparent"
                        border.width: 1.5
                        border.color: Theme.text
                    }
                    Rectangle {
                        x: 3
                        y: 10
                        width: 3
                        height: 13
                        radius: 1.5
                        color: Theme.text
                    }
                }
            }
        }
        // Computer: a screen on a stand.
        Item {
            visible: parent.family === "computer"
            anchors.centerIn: parent
            width: 26
            height: 22
            Rectangle {
                width: 26
                height: 17
                radius: 3
                color: "transparent"
                border.width: 1.5
                border.color: Theme.text
            }
            Rectangle {
                x: 8
                y: 20
                width: 10
                height: 1.5
                color: Theme.text
            }
        }
        SvgIcon {
            visible: ["keyboard", "mouse", "bluetooth"].includes(parent.family)
            anchors.centerIn: parent
            width: 22
            height: 22
            name: visible ? parent.family : "bluetooth"
        }
    }
    component Switch: Item {
        property string name: ""
        property bool checked: false
        signal toggled(bool value)
        width: parent.width
        height: 30
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.name
            font.pixelSize: 13
        }
        MenuToggle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: parent.checked
            hint: parent.name
            onToggled: value => parent.toggled(value)
        }
    }

    Item {
        anchors.fill: parent
        clip: true
        Item {
            width: menu.width * 2
            height: menu.height
            x: menu.selected ? -menu.width : 0
            Behavior on x {
                NumberAnimation {
                    duration: Theme.reducedMotion ? 0 : 260
                    easing.type: Easing.OutCubic
                }
            }

            // Page 1, laid out at the design's own coordinates.
            Item {
                width: menu.width
                height: menu.height
                opacity: menu.selected ? .4 : 1
                Behavior on opacity {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : 260 }
                }

                LineGlyph {
                    x: Theme.menuEdge + 6
                    y: Theme.menuTop + 1
                    width: 29
                    height: 40
                    kind: "bluetooth"
                    ink: "#ffffff"
                    opacity: menu.enabled ? 1 : .45
                    Component.onCompleted: requestPaint()
                }
                Text {
                    x: Theme.menuTextX
                    y: Theme.menuTop + 4
                    text: "Bluetooth"
                    font.family: Theme.font
                    font.pixelSize: 17
                    font.weight: Theme.boldWeight
                    color: "#ffffff"
                }
                Text {
                    x: Theme.menuTextX
                    y: Theme.menuTop + 26
                    text: !menu.adapter ? "No adapter" : menu.enabled ? "On" : "Off"
                    font.family: Theme.font
                    font.pixelSize: 14
                    color: "#ffffff"
                }
                MenuToggle {
                    x: menu.width - Theme.menuEdge - width
                    y: Theme.menuTop + 12
                    checked: menu.enabled
                    enabled: !!menu.adapter
                    hint: "Bluetooth"
                    onToggled: value => menu.adapter.enabled = value
                }
                Rectangle {
                    x: Theme.menuEdge
                    y: Theme.menuRule
                    width: Theme.menuInner
                    height: 1
                    color: "#d9d9d9"
                }
                Text {
                    visible: !menu.enabled
                    x: Theme.menuEdge
                    y: Theme.menuRule + Theme.menuSection
                    text: !menu.adapter ? "No Bluetooth adapter" : "Bluetooth is off"
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: "#939393"
                }

                Flickable {
                    id: deviceList
                    visible: menu.enabled
                    // Rows carry half their padding, so the first name sits a section below the rule.
                    y: Theme.menuRule + Theme.menuSection - (Theme.menuRow - 16) / 2
                    width: menu.width
                    height: menu.height - y - 16
                    contentHeight: devices.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: devices
                        width: menu.width

                        Repeater {
                            model: menu.paired
                            Item {
                                id: entry
                                required property var modelData
                                readonly property bool connected: modelData.connected
                                readonly property bool isPods: menu.headset === modelData && menu.podsReady
                                // AirPods stack their battery row and listening modes above Disconnect.
                                // Under the name: L/R/Case labels, their levels, the modes, then Disconnect.
                                readonly property real labelY: Theme.menuRow + 6
                                readonly property real levelY: labelY + 15 + Theme.menuGap
                                readonly property real modesY: levelY + 16 + Theme.menuGap
                                readonly property real disconnectY: isPods ? (listening.visible ? modesY + Theme.menuButton + Theme.menuGap : modesY) : Theme.menuRow + Theme.menuTight
                                // Width of one listening-mode button; each battery figure centres over one.
                                readonly property real third: (Theme.menuInner - 2 * Theme.menuGap) / 3
                                width: devices.width
                                height: connected ? disconnectY + Theme.menuButton + Theme.menuTight : Theme.menuRow

                                // Name row: kind, name, model, and battery or state on the right.
                                Item {
                                    width: parent.width
                                    height: Theme.menuRow
                                    Glyph {
                                        x: Theme.menuEdge + 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        kind: entry.modelData.icon || ""
                                    }
                                    Row {
                                        x: Theme.menuTextX
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            text: entry.modelData.name
                                            font.family: Theme.font
                                            font.pixelSize: 16
                                            font.weight: Theme.demiWeight
                                            color: "#ffffff"
                                        }
                                        Text {
                                            anchors.baseline: parent.children[0].baseline
                                            text: menu.subtitle(entry.modelData).replace("  -  ", " - ")
                                            font.family: Theme.font
                                            font.pixelSize: 14
                                            color: "#888888"
                                        }
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: Theme.menuEdge
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: entry.connected && !entry.modelData.pairing ? menu.batteryOf(entry.modelData) : menu.stateText(entry.modelData)
                                        font.family: Theme.font
                                        font.pixelSize: entry.connected ? 15 : 12
                                        color: entry.connected ? "#ffffff" : "#707070"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        // A connected device opens its options; the others connect.
                                        onClicked: entry.connected ? menu.selected = entry.modelData : menu.activate(entry.modelData)
                                    }
                                }
                                // AirPods: left, right and case.
                                Repeater {
                                    model: entry.isPods ? [
                                        {label: "L", column: 0, part: menu.pods.battery?.left ?? menu.pods.battery?.headset ?? null},
                                        {label: "R", column: 1, part: menu.pods.battery?.right ?? null},
                                        {label: "Case", column: 2, part: menu.pods.battery?.case ?? null}
                                    ] : []
                                    Item {
                                        required property var modelData
                                        x: Theme.menuEdge + modelData.column * (entry.third + Theme.menuGap) + entry.third / 2 - 40
                                        width: 80
                                        Text {
                                            y: entry.labelY
                                            width: 80
                                            horizontalAlignment: Text.AlignHCenter
                                            text: parent.modelData.label
                                            font.family: Theme.font
                                            font.pixelSize: 12
                                            color: "#616161"
                                        }
                                        Row {
                                            y: entry.levelY
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 3
                                            SvgIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 10
                                                height: 10
                                                name: "lightning"
                                                visible: !!parent.parent.modelData.part?.charging
                                            }
                                            Text {
                                                text: parent.parent.modelData.part ? parent.parent.modelData.part.level + "%" : "—"
                                                font.family: Theme.font
                                                font.pixelSize: 13
                                                color: "#ffffff"
                                            }
                                        }
                                    }
                                }
                                ListeningMode {
                                    id: listening
                                    visible: entry.isPods
                                    x: Theme.menuEdge
                                    y: entry.modesY
                                    width: Theme.menuInner
                                    spacing: Theme.menuGap
                                    buttonHeight: Theme.menuButton
                                }
                                // Disconnect: an outlined button under the listening modes.
                                Rectangle {
                                    visible: entry.connected
                                    x: Theme.menuEdge
                                    y: entry.disconnectY
                                    width: Theme.menuInner
                                    height: Theme.menuButton
                                    radius: 8
                                    color: disconnectArea.containsMouse ? "#1e1e1e" : "transparent"
                                    border.width: 1
                                    border.color: disconnectArea.containsMouse ? "#4a4a4a" : "#333333"
                                    Behavior on color {
                                        ColorAnimation { duration: Theme.reducedMotion ? 0 : 120 }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: Theme.reducedMotion ? 0 : 120 }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Disconnect"
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        font.weight: Theme.mediumWeight
                                        color: disconnectArea.containsMouse ? "#e89a9a" : "#bdbdbd"
                                        Behavior on color {
                                            ColorAnimation { duration: Theme.reducedMotion ? 0 : 120 }
                                        }
                                    }
                                    MouseArea {
                                        id: disconnectArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: entry.modelData.disconnect()
                                    }
                                }
                            }
                        }

                        // Nearby devices, found while the menu is open.
                        Item {
                            visible: menu.found.length > 0 || !!menu.adapter?.discovering
                            // A section heading: a section gap above, an item gap below.
                            width: devices.width
                            height: Theme.menuSection + 18 + Theme.menuGap - (Theme.menuRow - 18) / 2
                            Text {
                                x: Theme.menuEdge
                                y: Theme.menuSection
                                text: menu.found.length ? "Others" : "Looking for devices…"
                                font.family: Theme.font
                                font.pixelSize: Theme.menuHeading
                                color: Theme.menuHeadingInk
                            }
                        }
                        Repeater {
                            model: menu.found
                            Item {
                                required property var modelData
                                width: devices.width
                                height: Theme.menuRow
                                Text {
                                    x: Theme.menuEdge
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 300
                                    elide: Text.ElideRight
                                    text: parent.modelData.name
                                    font.family: Theme.font
                                    font.pixelSize: 15
                                    color: "#ffffff"
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.menuEdge
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.modelData.pairing ? "Pairing…" : "Pair"
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    color: "#707070"
                                    opacity: pairArea.containsMouse || parent.modelData.pairing ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: Theme.reducedMotion ? 0 : 120 }
                                    }
                                }
                                MouseArea {
                                    id: pairArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: menu.activate(parent.modelData)
                                }
                            }
                        }
                    }
                }
                // The list darkens into the frame where it runs past the bottom edge,
                // and at the top once it has been scrolled.
                Rectangle {
                    visible: deviceList.visible
                    y: deviceList.y + deviceList.height - height
                    width: menu.width - 2
                    x: 1
                    height: 56
                    opacity: deviceList.contentHeight > deviceList.height + 1 && !deviceList.atYEnd ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.reducedMotion ? 0 : 160 }
                    }
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#000f0f0f" }
                        GradientStop { position: 1; color: "#0f0f0f" }
                    }
                }
                Rectangle {
                    visible: deviceList.visible
                    y: deviceList.y
                    width: menu.width - 2
                    x: 1
                    height: 28
                    opacity: deviceList.contentY > 1 ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.reducedMotion ? 0 : 160 }
                    }
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#0f0f0f" }
                        GradientStop { position: 1; color: "#000f0f0f" }
                    }
                }
            }

            // Page 2: options for one device.
            Item {
                x: menu.width
                width: menu.width
                height: menu.height
                opacity: menu.selected ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : 260 }
                }
                Column {
                    x: Theme.menuEdge
                    y: Theme.menuTop
                    width: Theme.menuInner
                    spacing: Theme.menuGap
                    Row {
                        spacing: 10
                        Key {
                            width: 30
                            height: 30
                            radius: 8
                            hint: "Back"
                            onClicked: menu.selected = null
                            SvgIcon {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                name: "back"
                            }
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: menu.selected?.name ?? ""
                            font.pixelSize: 16
                            font.weight: Theme.boldWeight
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#5a5a5a"
                    }
                    Caption {
                        text: (menu.selected === menu.headset && menu.pods.model ? menu.pods.model + "  ·  " : "") + (menu.selected?.address ?? "")
                    }
                    Switch {
                        visible: menu.selected === menu.headset && menu.podsReady && menu.pods.conversation !== undefined
                        name: "Conversation awareness"
                        checked: !!menu.pods.conversation
                        onToggled: value => AirPods.send("conversation " + (value ? "on" : "off"))
                    }
                    Caption {
                        visible: menu.selected === menu.headset && !!menu.pods.error
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: menu.pods.error ?? ""
                    }
                    Switch {
                        name: "Connect automatically"
                        checked: !!menu.selected?.trusted
                        onToggled: value => menu.selected.trusted = value
                    }
                    Switch {
                        name: "Visible to other devices"
                        checked: !!menu.adapter?.discoverable
                        onToggled: value => menu.adapter.discoverable = value
                    }
                    Row {
                        spacing: 8
                        Key {
                            text: menu.selected?.connected ? "Disconnect" : "Connect"
                            height: 34
                            radius: 9
                            color: "#262626"
                            onClicked: menu.activate(menu.selected)
                        }
                        Key {
                            text: "Forget"
                            height: 34
                            radius: 9
                            ink: "#e08a8a"
                            onClicked: {
                                const device = menu.selected;
                                menu.selected = null;
                                device.forget();
                            }
                        }
                    }
                }
            }
        }
    }
}
