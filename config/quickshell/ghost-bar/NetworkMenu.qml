import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Wi-Fi menu under the top bar icon. The first page lists nearby networks with
// their link rate and signal, and live speeds for the connected one. Options,
// joining and sharing open on a second page that slides in from the right.
Item {
    id: menu
    property bool previewMode: false
    // False while the popup closes: the lists hold still during the fade.
    property bool active: true
    property var info: ({connected: false})      // From network.py details.
    property var networks: []                    // From network.py watch.
    property var speed: ({down: null, up: null})
    property bool showAll: false
    // Second page: "" (none), "options", "join", "share".
    property string page: ""
    property var joining: null                   // {name, secured} for the join page.
    property var qr: null                        // {name, rows} for the share page.
    property string error: ""
    readonly property var device: Desk.wifi
    readonly property var current: Desk.network
    readonly property string statusText: !device ? "No adapter" : !Networking.wifiEnabled ? "Off"
        : Desk.wired && !current ? "Ethernet" : current ? "Connected" : "Not connected"
    readonly property var providers: [
        {id: "auto", name: "Automatic"}, {id: "cloudflare", name: "Cloudflare"}, {id: "google", name: "Google"},
        {id: "quad9", name: "Quad9"}, {id: "adguard", name: "AdGuard"}
    ]
    readonly property string pageTitle: page === "share" ? "Share " + (qr?.name ?? "")
        : page === "join" ? (joining?.name || "Other network") : (info.name || "")
    // Row pitch and size from the design.
    readonly property real rowPitch: Theme.menuRow
    readonly property int visibleRows: 8
    width: Theme.menuWidth
    implicitHeight: 590

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
    function networkNamed(name) {
        return device?.networks.values.find(n => n.name === name) ?? null;
    }
    function open(entry) {
        if (entry.connected) {
            refresh();
            page = "options";
            return;
        }
        const network = networkNamed(entry.name);
        if (network && (entry.known || !entry.secured)) {
            network.connect();
            return;
        }
        joining = entry;
        page = "join";
    }
    function megabits(value) {
        return value === null || value === undefined ? "—" : value < 1 ? value.toFixed(2) : value < 10 ? value.toFixed(1) : Math.round(value);
    }
    onCurrentChanged: refresh()
    onActiveChanged: if (!active)
        page = ""
    Component.onCompleted: refresh()

    Process {
        id: watcher
        command: ["python3", Quickshell.shellPath("network.py"), "watch"]
        running: menu.active && !menu.previewMode
        stdout: SplitParser {
            onRead: line => {
                try {
                    const result = JSON.parse(line);
                    menu.networks = result.networks;
                    menu.speed = {down: result.down, up: result.up};
                } catch (_) {}
            }
        }
    }
    Process {
        id: helper
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    if (!result.ok)
                        menu.error = result.error;
                    else if (result.rows) {
                        menu.qr = result;
                        menu.page = "share";
                    } else
                        menu.info = result;
                } catch (_) {
                    menu.error = "Network helper failed";
                }
            }
        }
    }
    // Connection failures from Quickshell, for the network being joined.
    Connections {
        target: menu.joining ? menu.networkNamed(menu.joining.name) : null
        ignoreUnknownSignals: true
        function onConnectionFailed(reason) {
            menu.error = menu.joining.name + ": " + ConnectionFailReason.toString(reason);
        }
    }

    component Caption: Label {
        font.pixelSize: 11
        color: Theme.muted
    }
    component Field: Rectangle {
        property alias text: input.text
        property alias echoMode: input.echoMode
        property alias input: input
        property string placeholder: ""
        signal accepted
        width: parent.width
        height: 38
        radius: 9
        color: "#202020"
        border.width: 1
        border.color: input.activeFocus ? "#6a6a6a" : "#303030"
        Behavior on border.color {
            ColorAnimation { duration: Theme.reducedMotion ? 0 : 140 }
        }
        Label {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            opacity: input.text.length ? 0 : 1
            text: parent.placeholder
            color: Theme.faint
            font.pixelSize: 13
            Behavior on opacity {
                NumberAnimation { duration: Theme.reducedMotion ? 0 : 120 }
            }
        }
        TextInput {
            id: input
            x: 14
            width: parent.width - 28
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 13
            clip: true
            onAccepted: parent.accepted()
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
    component Back: Key {
        width: 30
        height: 30
        radius: 8
        hint: "Back"
        onClicked: {
            menu.page = "";
            menu.error = "";
        }
        SvgIcon {
            anchors.centerIn: parent
            width: 18
            height: 18
            name: "back"
        }
    }

    // Two pages side by side; the second slides in over the first.
    Item {
        anchors.fill: parent
        clip: true
        Item {
            id: pages
            width: menu.width * 2
            height: menu.height
            x: menu.page ? -menu.width : 0
            Behavior on x {
                NumberAnimation {
                    duration: Theme.reducedMotion ? 0 : 260
                    easing.type: Easing.OutCubic
                }
            }

            // Page 1, laid out at the design's own coordinates.
            Item {
                id: listPage
                width: menu.width
                height: menu.height
                opacity: menu.page ? .4 : 1
                Behavior on opacity {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : 260 }
                }

                SvgIcon {
                    x: Theme.menuEdge
                    y: Theme.menuTop
                    width: 42
                    height: 42
                    name: "wifi"
                    opacity: Networking.wifiEnabled ? 1 : .45
                }
                Row {
                    x: Theme.menuTextX
                    y: Theme.menuTop + 4
                    Text {
                        text: "WLAN"
                        font.family: Theme.font
                        font.pixelSize: 17
                        font.weight: Theme.boldWeight
                        color: "#ffffff"
                    }
                    Text {
                        anchors.baseline: parent.children[0].baseline
                        text: " - " + menu.statusText
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: "#939393"
                    }
                }
                Text {
                    x: Theme.menuTextX
                    y: Theme.menuTop + 26
                    text: Networking.wifiEnabled ? "On" : "Off"
                    font.family: Theme.font
                    font.pixelSize: 14
                    color: "#ffffff"
                }
                MenuToggle {
                    x: menu.width - Theme.menuEdge - width
                    y: Theme.menuTop + 12
                    checked: Networking.wifiEnabled
                    enabled: !!menu.device
                    hint: "Wi-Fi"
                    onToggled: value => Networking.wifiEnabled = value
                }
                Rectangle {
                    x: Theme.menuEdge
                    y: Theme.menuRule
                    width: Theme.menuInner
                    height: 1
                    color: "#d9d9d9"
                }

                // The connected network's speeds and signal, evenly spaced.
                Row {
                    id: stats
                    readonly property var connected: menu.networks.find(n => n.connected) ?? null
                    visible: Networking.wifiEnabled || !!Desk.wired
                    x: Theme.menuEdge
                    y: Theme.menuRule + Theme.menuSection
                    spacing: 0
                    Repeater {
                        model: [
                            {glyph: "up", value: menu.megabits(menu.speed.up), unit: "Mbps"},
                            {glyph: "down", value: menu.megabits(menu.speed.down), unit: "Mbps"},
                            {glyph: "radio", value: stats.connected ? String(stats.connected.dbm) : "—", unit: "dBm"}
                        ]
                        Item {
                            required property var modelData
                            width: Theme.menuInner / 3
                            height: 16
                            LineGlyph {
                                width: modelData.glyph === "radio" ? 21 : 14
                                height: modelData.glyph === "radio" ? 15 : 14
                                anchors.verticalCenter: parent.verticalCenter
                                kind: modelData.glyph
                                ink: modelData.glyph === "radio" ? "#818181" : "#666666"
                            }
                            Text {
                                x: modelData.glyph === "radio" ? 37 : 30
                                anchors.verticalCenter: parent.verticalCenter
                                // Live figures for whichever link is active; dBm needs Wi-Fi.
                                text: modelData.value + " " + modelData.unit
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: "#a4a4a4"
                            }
                        }
                    }
                }
                Text {
                    visible: !Networking.wifiEnabled || !menu.device
                    x: Theme.menuEdge
                    y: Theme.menuRule + Theme.menuSection
                    text: !menu.device ? "No Wi-Fi adapter" : "Wi-Fi is off"
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: "#939393"
                }

                // Networks: the connected one in a filled circle, then by signal.
                Flickable {
                    id: list
                    visible: Networking.wifiEnabled
                    x: 0
                    y: Theme.menuRule + Theme.menuSection + 16 + Theme.menuGap - (Theme.menuRow - 36) / 2
                    width: menu.width
                    height: menu.rowPitch * menu.visibleRows
                    contentHeight: listColumn.height
                    interactive: menu.showAll
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: listColumn
                        width: list.width
                        Repeater {
                            model: menu.showAll ? menu.networks : menu.networks.slice(0, menu.visibleRows)
                            Item {
                                id: row
                                required property var modelData
                                width: listColumn.width
                                height: menu.rowPitch
                                Rectangle {
                                    x: Theme.menuEdge
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 36
                                    height: 36
                                    radius: 18
                                    color: "#d9d9d9"
                                    visible: row.modelData.connected
                                }
                                LineGlyph {
                                    x: Theme.menuEdge + 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 22
                                    height: 16
                                    kind: "wifi"
                                    ink: row.modelData.connected ? "#3e3e3e" : "#ffffff"
                                }
                                Text {
                                    x: Theme.menuTextX
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 110
                                    elide: Text.ElideRight
                                    text: row.modelData.name
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    color: "#ffffff"
                                }
                                Text {
                                    x: 198
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (row.modelData.rate ?? "—") + " Mbps"
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    color: "#575757"
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.menuEdge
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.dbm + " dBm"
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    color: "#575757"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: menu.open(row.modelData)
                                }
                            }
                        }
                        Item {
                            visible: menu.showAll
                            width: listColumn.width
                            height: menu.rowPitch
                            Text {
                                x: Theme.menuTextX
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Other network…"
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: "#939393"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    menu.joining = {name: "", secured: true};
                                    menu.page = "join";
                                }
                            }
                        }
                    }
                }
                Text {
                    visible: Networking.wifiEnabled && (menu.networks.length > menu.visibleRows || menu.showAll)
                    x: (menu.width - width) / 2
                    y: list.y + list.height + Theme.menuGap
                    text: menu.showAll ? "Less" : "More"
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: "#ffffff"
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            menu.showAll = !menu.showAll;
                            list.contentY = 0;
                        }
                    }
                }
            }

            // Page 2: options, joining or sharing.
            Item {
                x: menu.width
                width: menu.width
                height: menu.height
                opacity: menu.page ? 1 : 0
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
                        Back {}
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.menuInner - 40
                            text: menu.pageTitle
                            font.pixelSize: 16
                            font.weight: Theme.boldWeight
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#5a5a5a"
                    }

                    // Options for the connected network.
                    Column {
                        visible: menu.page === "options"
                        width: parent.width
                        spacing: 12
                        Grid {
                            columns: 2
                            columnSpacing: 18
                            rowSpacing: 6
                            Caption { text: "Address" }
                            Label { text: menu.info.address || "—"; font.pixelSize: 12 }
                            Caption { text: "Gateway" }
                            Label { text: menu.info.gateway || "—"; font.pixelSize: 12 }
                            Caption { text: "DNS" }
                            Label { text: (menu.info.dns || []).join(", ") || "—"; font.pixelSize: 12; width: 260 }
                            Caption { text: "Speed" }
                            Label { text: "↓ " + menu.megabits(menu.speed.down) + "  ↑ " + menu.megabits(menu.speed.up) + " Mbps"; font.pixelSize: 12 }
                        }
                        Caption { text: "DNS provider" }
                        Flow {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: menu.providers
                                Key {
                                    required property var modelData
                                    text: modelData.name
                                    height: 30
                                    radius: 15
                                    padding: 12
                                    fontSize: 12
                                    selected: menu.info.provider === modelData.id
                                    color: selected ? Theme.text : "#262626"
                                    onClicked: menu.run(["dns", menu.info.name, modelData.id])
                                }
                            }
                        }
                        Switch {
                            name: "Join automatically"
                            checked: !!menu.info.autoconnect
                            onToggled: value => menu.run(["autoconnect", menu.info.name, value ? "yes" : "no"])
                        }
                        Switch {
                            name: "Private address"
                            checked: !!menu.info.private
                            onToggled: value => menu.run(["private", menu.info.name, value ? "yes" : "no"])
                        }
                        Row {
                            spacing: 8
                            Key {
                                text: "Share as QR code"
                                height: 34
                                radius: 9
                                color: "#262626"
                                onClicked: menu.run(["share", menu.info.name || menu.current.name])
                            }
                            Key {
                                text: "Disconnect"
                                height: 34
                                radius: 9
                                color: "#262626"
                                onClicked: {
                                    menu.current?.disconnect();
                                    menu.page = "";
                                }
                            }
                            Key {
                                text: "Forget"
                                height: 34
                                radius: 9
                                ink: "#e08a8a"
                                onClicked: {
                                    menu.current?.forget();
                                    menu.page = "";
                                }
                            }
                        }
                    }

                    // Joining: a password, and a name for networks that are not listed.
                    Column {
                        visible: menu.page === "join"
                        width: parent.width
                        spacing: 10
                        Field {
                            id: joinName
                            visible: menu.page === "join" && !menu.joining?.name
                            placeholder: "Network name"
                        }
                        Field {
                            id: joinPassword
                            visible: menu.page === "join" && !!menu.joining?.secured
                            placeholder: menu.joining?.name ? "Password" : "Password (empty if open)"
                            echoMode: TextInput.Password
                            onAccepted: joinButton.clicked()
                        }
                        Key {
                            id: joinButton
                            text: "Join"
                            height: 34
                            radius: 9
                            color: "#262626"
                            enabled: !!menu.joining?.name || joinName.text.length > 0
                            onClicked: {
                                if (menu.joining?.name)
                                    menu.networkNamed(menu.joining.name)?.connectWithPsk(joinPassword.text);
                                else
                                    menu.run(joinPassword.text ? ["hidden", joinName.text, joinPassword.text] : ["hidden", joinName.text]);
                                joinPassword.text = "";
                                joinName.text = "";
                                menu.page = "";
                            }
                        }
                    }

                    // Sharing: a code a phone camera joins from.
                    Column {
                        visible: menu.page === "share" && !!menu.qr
                        width: parent.width
                        spacing: 12
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 250
                            height: 250
                            radius: 14
                            color: "#f4f4f4"
                            Canvas {
                                anchors.centerIn: parent
                                readonly property var rows: menu.qr?.rows ?? []
                                width: 220
                                height: 220
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
                        Caption {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "Scan with a phone camera to join"
                        }
                    }

                    Label {
                        visible: menu.error !== ""
                        width: parent.width
                        text: menu.error
                        wrapMode: Text.WordWrap
                        color: "#e08a8a"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    // Focus the field the join page needs once it has slid in.
    onPageChanged: if (page === "join")
        Qt.callLater(() => (menu.joining?.name ? joinPassword : joinName).input.forceActiveFocus())
}
