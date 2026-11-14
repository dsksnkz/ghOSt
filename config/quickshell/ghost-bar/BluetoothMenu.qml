import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Bluetooth menu under the top bar icon. Pairing, connecting and forgetting
// happen here through BlueZ, without an external manager. Connected AirPods
// also get per-bud battery and listening modes through airpods.py.
Item {
    id: menu
    property bool previewMode: false
    // False while the popup closes, so the lists do not change during the fade.
    property bool active: true
    property string expanded: ""        // Address of the device showing its options.
    property var pods: ({})             // Latest status line from airpods.py.
    readonly property var adapter: Desk.adapter
    readonly property bool enabled: !!adapter?.enabled
    readonly property var known: Bluetooth.devices.values.filter(d => d.paired || d.connected)
        .sort((a, b) => Number(b.connected) - Number(a.connected) || a.name.localeCompare(b.name))
    readonly property var liveFound: Bluetooth.devices.values.filter(d => !d.paired && !d.connected && d.deviceName)
        .sort((a, b) => a.name.localeCompare(b.name)).slice(0, 8)
    property var found: []
    Binding on found {
        value: menu.liveFound
        when: menu.active
        restoreMode: Binding.RestoreNone
    }
    // Only a connected headset can be AirPods; airpods.py checks the vendor itself.
    readonly property var headset: known.find(d => d.connected && (d.icon || "").startsWith("audio-head")) ?? null
    readonly property bool podsReady: !!pods.apple && !!pods.connected
    readonly property var modes: [
        {id: "off", name: "Off"}, {id: "transparency", name: "Transparency"},
        {id: "adaptive", name: "Adaptive"}, {id: "anc", name: "Noise cancelling"}
    ]
    implicitHeight: column.implicitHeight + 32

    function percent(value) {
        return Math.round(value * 100) + "%";
    }
    function stateText(device) {
        if (device.pairing)
            return "Pairing…";
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (device.connected)
            return device.batteryAvailable ? "Connected · " + percent(device.battery) : "Connected";
        return "";
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
    function send(line) {
        if (pods.connected)
            podsProcess.write(line + "\n");
    }
    // Stop scanning when the menu closes; discovery costs power and radio time.
    Component.onDestruction: if (adapter?.discovering && !previewMode)
        adapter.discovering = false

    Process {
        id: podsProcess
        command: ["python3", Quickshell.shellPath("airpods.py"), menu.headset?.address ?? ""]
        running: !menu.previewMode && !!menu.headset
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    menu.pods = JSON.parse(line);
                } catch (_) {}
            }
        }
        onRunningChanged: if (!running)
            menu.pods = {}
    }

    component Caption: Label {
        font.pixelSize: 10
        color: Theme.muted
    }
    component Part: Column {
        property string name: ""
        property var part: null
        width: (column.width - 20) / 3
        spacing: 2
        opacity: part ? 1 : .35
        Caption {
            text: parent.name
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3
            SvgIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 11
                height: 11
                name: "lightning"
                visible: !!parent.parent.part?.charging
            }
            Label {
                text: parent.parent.part ? parent.parent.part.level + "%" : "—"
                font.pixelSize: 13
                font.weight: Theme.mediumWeight
            }
        }
    }

    Column {
        id: column
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 6

        Item {
            width: parent.width
            height: 30
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                SvgIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    name: "bluetooth"
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth"
                    font.pixelSize: 15
                    font.weight: Theme.demiWeight
                }
            }
            SettingsToggle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: menu.enabled
                enabled: !!menu.adapter
                hint: "Bluetooth"
                onToggled: value => menu.adapter.enabled = value
            }
        }
        Caption {
            visible: !menu.adapter
            text: "No Bluetooth adapter"
        }

        Repeater {
            model: menu.enabled ? menu.known : []
            Column {
                id: entry
                required property var modelData
                readonly property bool open: menu.expanded === modelData.address
                readonly property bool isPods: menu.headset === modelData && menu.podsReady
                width: column.width
                spacing: 6
                Key {
                    width: parent.width
                    height: 40
                    radius: 8
                    pressFeedback: false
                    hint: entry.modelData.name
                    onClicked: menu.activate(entry.modelData)
                    SvgIcon {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        name: (entry.modelData.icon || "").startsWith("audio") ? "volume" : (entry.modelData.icon || "").startsWith("input-mouse") ? "mouse" : (entry.modelData.icon || "").startsWith("input-keyboard") ? "keyboard" : "bluetooth"
                        opacity: entry.modelData.connected ? 1 : .45
                    }
                    Column {
                        x: 32
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 70
                        Label {
                            width: parent.width
                            text: entry.modelData.name
                            font.pixelSize: 12
                            font.weight: entry.modelData.connected ? Theme.mediumWeight : Font.Normal
                            color: entry.modelData.connected ? Theme.text : "#cfcfcf"
                        }
                        Caption {
                            visible: text !== ""
                            text: menu.stateText(entry.modelData)
                        }
                    }
                    Key {
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        hint: "Options"
                        onClicked: menu.expanded = entry.open ? "" : entry.modelData.address
                        SvgIcon {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            name: entry.open ? "up" : "down"
                        }
                    }
                }
                // AirPods: each bud and the case, and the listening mode.
                Column {
                    visible: entry.isPods
                    width: parent.width
                    spacing: 8
                    Row {
                        spacing: 10
                        Part { name: "Left"; part: menu.pods.battery?.left ?? menu.pods.battery?.headset ?? null }
                        Part { name: "Right"; part: menu.pods.battery?.right ?? null }
                        Part { name: "Case"; part: menu.pods.battery?.case ?? null }
                    }
                    Row {
                        visible: !!menu.pods.mode
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: menu.modes
                            Key {
                                required property var modelData
                                width: (entry.width - 12) / 4
                                height: 28
                                radius: 8
                                text: modelData.name
                                fontSize: 10
                                selected: menu.pods.mode === modelData.id
                                color: selected ? Theme.text : "#2a2a2a"
                                onClicked: menu.send("mode " + modelData.id)
                            }
                        }
                    }
                    Item {
                        visible: menu.pods.conversation !== undefined
                        width: parent.width
                        height: 24
                        Label { anchors.verticalCenter: parent.verticalCenter; text: "Conversation awareness"; font.pixelSize: 12 }
                        SettingsToggle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: !!menu.pods.conversation
                            hint: "Conversation awareness"
                            onToggled: value => menu.send("conversation " + (value ? "on" : "off"))
                        }
                    }
                }
                Caption {
                    visible: entry.open && menu.headset === entry.modelData && !!menu.pods.error
                    text: menu.pods.error ?? ""
                }
                // Per-device options.
                Column {
                    visible: entry.open
                    width: parent.width
                    spacing: 6
                    Item {
                        width: parent.width
                        height: 24
                        Label { anchors.verticalCenter: parent.verticalCenter; text: "Connect automatically"; font.pixelSize: 12 }
                        SettingsToggle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: entry.modelData.trusted
                            hint: "Connect automatically"
                            onToggled: value => entry.modelData.trusted = value
                        }
                    }
                    Caption {
                        text: entry.modelData.address
                    }
                    Row {
                        spacing: 6
                        Key {
                            text: entry.modelData.connected ? "Disconnect" : "Connect"
                            height: 28
                            color: "#2a2a2a"
                            onClicked: menu.activate(entry.modelData)
                        }
                        Key {
                            text: "Forget"
                            height: 28
                            ink: "#e08a8a"
                            onClicked: {
                                menu.expanded = "";
                                entry.modelData.forget();
                            }
                        }
                    }
                }
            }
        }

        // New devices appear while scanning.
        Item {
            visible: menu.enabled
            width: parent.width
            height: 30
            Caption {
                anchors.verticalCenter: parent.verticalCenter
                text: menu.adapter?.discovering ? "Looking for devices…" : "Other devices"
            }
            Key {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 26
                text: menu.adapter?.discovering ? "Stop" : "Scan"
                color: "#2a2a2a"
                onClicked: menu.adapter.discovering = !menu.adapter.discovering
            }
        }
        Repeater {
            model: menu.enabled && menu.adapter?.discovering ? menu.found : []
            Key {
                required property var modelData
                width: column.width
                height: 34
                radius: 8
                pressFeedback: false
                hint: "Pair " + modelData.name
                onClicked: menu.activate(modelData)
                Label {
                    x: 32
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 100
                    text: parent.modelData.name
                    font.pixelSize: 12
                    color: "#cfcfcf"
                }
                Caption {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.modelData.pairing ? "Pairing…" : "Pair"
                }
            }
        }
        Item {
            visible: menu.enabled
            width: parent.width
            height: 24
            Label { anchors.verticalCenter: parent.verticalCenter; text: "Visible to other devices"; font.pixelSize: 12 }
            SettingsToggle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: !!menu.adapter?.discoverable
                hint: "Visible to other devices"
                onToggled: value => menu.adapter.discoverable = value
            }
        }
    }
}
