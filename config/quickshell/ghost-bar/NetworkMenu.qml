import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Wi-Fi menu under the top bar icon: the current network and its options,
// nearby networks, joining with a password, hidden networks and sharing as a QR code.
Item {
    id: menu
    property bool previewMode: false
    // False while the popup closes. Scanning stops then and NetworkManager drops
    // the networks it found, so the list keeps plain copies (never the live
    // objects, which disappear mid-fade) and holds still until it reopens.
    property bool active: true
    property var info: ({connected: false})
    property string expanded: ""      // Network whose password field is open.
    property bool showDetails: false
    property var qr: null             // {name, rows} while the share view is open.
    property bool hiddenForm: false
    property string error: ""
    readonly property var device: Desk.wifi
    readonly property var current: Desk.network
    readonly property var liveNearby: (device?.networks.values ?? []).filter(n => !n.connected && n.name)
        .sort((a, b) => Number(b.known) - Number(a.known) || b.signalStrength - a.signalStrength).slice(0, 8)
        .map(n => ({name: n.name, known: n.known, signal: n.signalStrength, secured: secured(n)}))
    property var nearby: []
    Binding on nearby {
        value: menu.liveNearby
        when: menu.active
        restoreMode: Binding.RestoreNone
    }
    readonly property var providers: [
        {id: "auto", name: "Automatic"}, {id: "cloudflare", name: "Cloudflare"}, {id: "google", name: "Google"},
        {id: "quad9", name: "Quad9"}, {id: "adguard", name: "AdGuard"}
    ]
    implicitHeight: column.implicitHeight + 32

    function run(args) {
        if (previewMode || helper.running)
            return;
        error = "";
        helper.command = ["python3", Quickshell.shellPath("network.py")].concat(args);
        helper.running = true;
    }
    function refresh() {
        if (current)
            run(["details"]);
        else
            info = {connected: false};
    }
    function secured(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }
    function networkNamed(name) {
        return device?.networks.values.find(n => n.name === name) ?? null;
    }
    function join(entry) {
        const network = networkNamed(entry.name);
        if (!network)
            return;
        if (entry.known || !entry.secured) {
            network.connect();
            expanded = "";
        } else
            expanded = expanded === entry.name ? "" : entry.name;
    }
    onCurrentChanged: refresh()
    Component.onCompleted: refresh()

    Process {
        id: helper
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    if (!result.ok)
                        menu.error = result.error;
                    else if (result.rows)
                        menu.qr = result;
                    else
                        menu.info = result;
                } catch (_) {
                    menu.error = "Network helper failed";
                }
            }
        }
    }

    component Row2: Key {
        width: column.width
        height: 34
        radius: 8
        pressFeedback: false
    }
    component Caption: Label {
        font.pixelSize: 10
        color: Theme.muted
    }
    component Field: Rectangle {
        property alias text: input.text
        property alias echoMode: input.echoMode
        property string placeholder: ""
        signal accepted
        width: column.width
        height: 32
        radius: 8
        color: "#232323"
        border.width: input.activeFocus ? 1 : 0
        border.color: "#8a8a8a"
        Label {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: parent.placeholder
            color: Theme.faint
            font.pixelSize: 12
        }
        TextInput {
            id: input
            x: 12
            width: parent.width - 24
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 12
            clip: true
            onAccepted: parent.accepted()
            Component.onCompleted: forceActiveFocus()
        }
    }

    Column {
        id: column
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 6

        // Header: title and the radio switch.
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
                    name: "wifi"
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: menu.qr ? "Share " + menu.qr.name : "Wi-Fi"
                    font.pixelSize: 15
                    font.weight: Theme.demiWeight
                }
            }
            SettingsToggle {
                visible: !menu.qr
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: Networking.wifiEnabled
                enabled: !!menu.device
                hint: "Wi-Fi"
                onToggled: value => Networking.wifiEnabled = value
            }
            Key {
                visible: !!menu.qr
                anchors.right: parent.right
                width: 30
                height: 30
                hint: "Back"
                onClicked: menu.qr = null
                SvgIcon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    name: "close"
                }
            }
        }

        // Share view: a code phones scan with the camera to join.
        Item {
            visible: !!menu.qr
            width: parent.width
            height: visible ? 236 : 0
            Rectangle {
                id: qrPaper
                anchors.centerIn: parent
                width: 224
                height: 224
                radius: 12
                color: "#f4f4f4"
                Canvas {
                    id: qrCanvas
                    anchors.centerIn: parent
                    readonly property var rows: menu.qr?.rows ?? []
                    width: 196
                    height: 196
                    onRowsChanged: requestPaint()
                    onPaint: {
                        const context = getContext("2d");
                        context.reset();
                        if (!rows.length)
                            return;
                        const cell = Math.floor(width / rows.length);
                        const offset = Math.floor((width - cell * rows.length) / 2);
                        context.fillStyle = "#101010";
                        for (let y = 0; y < rows.length; y++)
                            for (let x = 0; x < rows.length; x++)
                                if (rows[y][x] === "1")
                                    context.fillRect(offset + x * cell, offset + y * cell, cell, cell);
                    }
                }
            }
        }
        Caption {
            visible: !!menu.qr
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Scan with a phone camera to join"
        }

        Caption {
            visible: !menu.qr && !menu.device
            text: "No Wi-Fi adapter"
        }
        Caption {
            visible: !menu.qr && !!Desk.wired
            text: "Ethernet connected"
        }

        // The current network and its options.
        Rectangle {
            visible: !menu.qr && !!menu.current
            width: parent.width
            height: visible ? currentColumn.implicitHeight + 16 : 0
            radius: 10
            color: "#222222"
            Column {
                id: currentColumn
                x: 10
                y: 8
                width: parent.width - 20
                spacing: 6
                Item {
                    width: parent.width
                    height: 32
                    SvgIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        name: "wifi"
                    }
                    Column {
                        x: 26
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 26 - 130
                        Label {
                            width: parent.width
                            text: menu.current?.name ?? ""
                            font.pixelSize: 13
                            font.weight: Theme.mediumWeight
                        }
                        Caption {
                            text: menu.info.address || "Connected"
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Key {
                            text: "Share"
                            height: 30
                            hint: "Share as QR code"
                            onClicked: menu.run(["share", menu.info.name || menu.current.name])
                        }
                        Key {
                            width: 30
                            height: 30
                            hint: "Options"
                            selected: menu.showDetails
                            onClicked: menu.showDetails = !menu.showDetails
                            SvgIcon {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                name: "settings"
                                black: menu.showDetails
                            }
                        }
                        Key {
                            width: 30
                            height: 30
                            hint: "Disconnect"
                            onClicked: menu.current.disconnect()
                            SvgIcon {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                name: "close"
                            }
                        }
                    }
                }
                // Options for the current network.
                Column {
                    visible: menu.showDetails && menu.info.connected
                    width: parent.width
                    spacing: 8
                    Grid {
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 3
                        Caption { text: "Gateway" }
                        Label { text: menu.info.gateway || "—"; font.pixelSize: 11 }
                        Caption { text: "DNS" }
                        Label { text: (menu.info.dns || []).join(", ") || "—"; font.pixelSize: 11; width: currentColumn.width - 70 }
                    }
                    Caption { text: "DNS provider" }
                    Flow {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: menu.providers
                            Key {
                                required property var modelData
                                text: modelData.name
                                height: 26
                                radius: 13
                                padding: 10
                                selected: menu.info.provider === modelData.id
                                color: selected ? Theme.text : "#2e2e2e"
                                onClicked: menu.run(["dns", menu.info.name, modelData.id])
                            }
                        }
                    }
                    Item {
                        width: parent.width
                        height: 24
                        Label { anchors.verticalCenter: parent.verticalCenter; text: "Join automatically"; font.pixelSize: 12 }
                        SettingsToggle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: !!menu.info.autoconnect
                            hint: "Join automatically"
                            onToggled: value => menu.run(["autoconnect", menu.info.name, value ? "yes" : "no"])
                        }
                    }
                    Item {
                        width: parent.width
                        height: 24
                        Label { anchors.verticalCenter: parent.verticalCenter; text: "Private address"; font.pixelSize: 12 }
                        SettingsToggle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: !!menu.info.private
                            hint: "Private address"
                            onToggled: value => menu.run(["private", menu.info.name, value ? "yes" : "no"])
                        }
                    }
                    Key {
                        text: "Forget this network"
                        height: 28
                        ink: "#e08a8a"
                        onClicked: {
                            menu.current.forget();
                            menu.showDetails = false;
                        }
                    }
                }
            }
        }

        Caption {
            visible: !menu.qr && Networking.wifiEnabled && menu.nearby.length > 0
            topPadding: 6
            text: "Networks"
        }
        Repeater {
            model: menu.qr || !Networking.wifiEnabled ? [] : menu.nearby
            Column {
                id: entry
                required property var modelData
                width: column.width
                spacing: 4
                Row2 {
                    hint: entry.modelData.name
                    onClicked: menu.join(entry.modelData)
                    SvgIcon {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        name: "wifi"
                        opacity: .35 + .65 * Math.min(1, entry.modelData.signal)
                    }
                    Label {
                        x: 32
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 70
                        text: entry.modelData.name
                        font.pixelSize: 12
                        color: entry.modelData.known ? Theme.text : "#cfcfcf"
                    }
                    SvgIcon {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        name: "lock"
                        opacity: .55
                        visible: entry.modelData.secured
                    }
                    Connections {
                        target: menu.networkNamed(entry.modelData.name)
                        ignoreUnknownSignals: true
                        function onConnectionFailed(reason) {
                            menu.error = entry.modelData.name + ": " + ConnectionFailReason.toString(reason);
                        }
                    }
                }
                Field {
                    visible: menu.expanded === entry.modelData.name
                    placeholder: "Password"
                    echoMode: TextInput.Password
                    onAccepted: {
                        menu.networkNamed(entry.modelData.name)?.connectWithPsk(text);
                        menu.expanded = "";
                    }
                }
            }
        }

        // Networks that do not broadcast their name.
        Key {
            visible: !menu.qr && Networking.wifiEnabled && !menu.hiddenForm
            text: "Hidden network…"
            height: 28
            ink: Theme.muted
            onClicked: menu.hiddenForm = true
        }
        Column {
            visible: !menu.qr && menu.hiddenForm
            width: parent.width
            spacing: 6
            Field {
                id: hiddenName
                placeholder: "Network name"
            }
            Field {
                id: hiddenPassword
                placeholder: "Password (leave empty if open)"
                echoMode: TextInput.Password
                onAccepted: join.clicked()
            }
            Row {
                spacing: 6
                Key {
                    id: join
                    text: "Join"
                    height: 28
                    color: "#2e2e2e"
                    enabled: hiddenName.text.length > 0
                    onClicked: {
                        menu.run(hiddenPassword.text ? ["hidden", hiddenName.text, hiddenPassword.text] : ["hidden", hiddenName.text]);
                        menu.hiddenForm = false;
                    }
                }
                Key {
                    text: "Cancel"
                    height: 28
                    onClicked: menu.hiddenForm = false
                }
            }
        }

        Label {
            visible: menu.error !== ""
            width: parent.width
            text: menu.error
            wrapMode: Text.WordWrap
            color: "#e08a8a"
            font.pixelSize: 11
        }
    }
}
