import QtQuick

// ghOSt SDDM greeter (Qt 6, SDDM 0.21+). Editorial left layout: clock and login
// on a left column, the ghost as a faint outline on the right.
// Uses only SDDM's context objects: sddm, userModel, sessionModel, keyboard, config.
Item {
    id: root
    width: 1920
    height: 1080

    readonly property string sans: "Adwaita Sans"
    readonly property color field: "#0b0b0c"
    readonly property color ink: "#ececea"
    readonly property color muted: "#8c8c8a"
    readonly property color well: "#141415"
    readonly property color edge: "#2a2a2b"
    readonly property color edgeHover: "#4a4a4b"
    readonly property real radius: 10
    // Content is drawn on a 1920 × 1080 plane and scaled to fit; the
    // background always fills the whole screen.
    readonly property real fit: Math.min(width / 1920, height / 1080)

    // SDDM user roles: 257 name, 258 real name, 261 needs password.
    property int userIndex: Math.max(0, userModel.lastIndex)
    readonly property string userName: userModel.data(userModel.index(userIndex, 0), 257) || ""
    readonly property string realName: userModel.data(userModel.index(userIndex, 0), 258) || ""
    // SDDM session role 260: display name.
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    readonly property string sessionName: sessionModel.data(sessionModel.index(sessionIndex, 0), 260) || "Session"
    readonly property bool hasLayouts: !!keyboard && !!keyboard.layouts && keyboard.layouts.length > 0
    readonly property string layoutName: hasLayouts ? keyboard.layouts[keyboard.currentLayout].longName : ""
    property string error: ""
    property bool busy: false
    property date now: new Date()

    function setting(key, fallback) {
        const value = config.stringValue(key);
        return value && value.length ? value : fallback;
    }
    function login() {
        if (busy || !userName)
            return;
        busy = true;
        error = "";
        sddm.login(userName, password.text, sessionIndex);
    }
    function step(count, index, delta) {
        return count > 0 ? (index + delta + count) % count : 0;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.error = "Incorrect password";
            password.text = "";
            password.forceActiveFocus();
            shake.restart();
        }
        function onLoginSucceeded() {
            root.busy = false;
        }
    }

    // ── Background: off-black field, soft light, fine grain ─────────────
    Rectangle {
        anchors.fill: parent
        color: root.field
    }
    Canvas {
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d");
            const cx = width * .22, cy = height * .39, r = Math.max(width, height) * .57;
            const g = c.createRadialGradient(cx, cy, 0, cx, cy, r);
            g.addColorStop(0, "rgba(255,255,255,0.055)");
            g.addColorStop(1, "rgba(255,255,255,0)");
            c.fillStyle = g;
            c.fillRect(0, 0, width, height);
            let seed = 7;
            const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
            const count = Math.round(width * height * .045);
            for (let i = 0; i < count; i++) {
                c.fillStyle = rnd() > .5 ? "rgba(255,255,255,0.03)" : "rgba(0,0,0,0.05)";
                c.fillRect(Math.floor(rnd() * width), Math.floor(rnd() * height), 1, 1);
            }
        }
    }

    Item {
        id: plane
        width: 1920
        height: 1080
        anchors.centerIn: parent
        scale: root.fit

        Image {
            visible: root.setting("watermark", "true") !== "false"
            x: 1060
            y: -140
            width: 1300
            height: 1300
            rotation: -8
            opacity: .08
            source: "assets/ghost-outline.svg"
            sourceSize.width: 2600
            sourceSize.height: 2600
        }

        Row {
            x: 240
            y: 76
            spacing: 12
            Image {
                width: 24
                height: 24
                source: "assets/icons/ghost.svg"
                sourceSize.width: 96
                sourceSize.height: 96
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ghOSt"
                font.family: root.sans
                font.pixelSize: 16
                font.weight: 550
                color: root.ink
            }
        }

        Column {
            x: 240
            y: 268
            width: 440

            Text {
                objectName: "clock"
                leftPadding: -6
                text: Qt.formatDateTime(root.now, root.setting("clockFormat", "HH:mm"))
                font.family: clockFont.name
                font.pixelSize: 168
                font.weight: Font.Light
                font.letterSpacing: -5
                color: root.ink
                FontLoader {
                    id: clockFont
                    source: "assets/fonts/JetBrainsMono-Light.ttf"
                }
            }
            Text {
                text: Qt.formatDateTime(root.now, root.setting("dateFormat", "dddd, d MMMM"))
                font.family: root.sans
                font.pixelSize: 20
                color: root.muted
            }
            Item {
                width: 1
                height: 92
            }

            // User: click the name or use the arrows to switch when several exist.
            Row {
                spacing: 14
                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: root.well
                    border.color: root.edge
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: (root.realName || root.userName).charAt(0).toUpperCase()
                        font.family: root.sans
                        font.pixelSize: 17
                        font.weight: 500
                        color: root.ink
                    }
                }
                Text {
                    objectName: "user-name"
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.realName || root.userName
                    font.family: root.sans
                    font.pixelSize: 20
                    font.weight: 500
                    color: root.ink
                }
                Row {
                    visible: userModel.count > 1
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: [["back", -1], ["forward", 1]]
                        Rectangle {
                            required property var modelData
                            width: 28
                            height: 28
                            radius: root.radius - 4
                            color: hover.hovered ? root.well : "transparent"
                            Image {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                source: "assets/icons/" + parent.modelData[0] + ".svg"
                                sourceSize.width: 56
                                sourceSize.height: 56
                                opacity: .75
                            }
                            HoverHandler {
                                id: hover
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: {
                                    root.userIndex = root.step(userModel.count, root.userIndex, parent.modelData[1]);
                                    root.error = "";
                                    password.text = "";
                                    password.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
            Item {
                width: 1
                height: 28
            }

            Text {
                bottomPadding: 10
                text: "Password"
                font.family: root.sans
                font.pixelSize: 13
                color: root.muted
            }
            Item {
                id: shaker
                width: 420
                height: 52
                SequentialAnimation {
                    id: shake
                    loops: 1
                    NumberAnimation { target: shaker; property: "x"; to: -8; duration: 50 }
                    NumberAnimation { target: shaker; property: "x"; to: 7; duration: 60 }
                    NumberAnimation { target: shaker; property: "x"; to: -4; duration: 60 }
                    NumberAnimation { target: shaker; property: "x"; to: 0; duration: 70 }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: root.radius
                    color: root.well
                    border.width: 1
                    border.color: root.error ? "#8c8c8a" : password.activeFocus ? "#5a5a5b" : "#3a3a3b"
                    TextInput {
                        id: password
                        objectName: "password"
                        x: 18
                        width: parent.width - 18 - 56
                        anchors.verticalCenter: parent.verticalCenter
                        focus: true
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        font.family: root.sans
                        font.pixelSize: 18
                        font.letterSpacing: 3
                        color: root.ink
                        selectionColor: "#3a3a3b"
                        clip: true
                        enabled: !root.busy
                        Keys.onReturnPressed: root.login()
                        Keys.onEnterPressed: root.login()
                        onTextEdited: root.error = ""
                    }
                    Rectangle {
                        objectName: "submit"
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 42
                        height: 42
                        radius: root.radius - 4
                        color: submitHover.hovered ? "#ffffff" : root.ink
                        opacity: root.busy ? .5 : 1
                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: "assets/icons/forward-black.svg"
                            sourceSize.width: 72
                            sourceSize.height: 72
                        }
                        HoverHandler {
                            id: submitHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: root.login()
                        }
                    }
                }
            }
            Text {
                objectName: "status"
                topPadding: 12
                text: root.error ? root.error : root.busy ? "Signing in" : keyboard.capsLock ? "Caps Lock is on" : "Caps Lock is off"
                font.family: root.sans
                font.pixelSize: 13
                font.weight: root.error || keyboard.capsLock ? 550 : Font.Normal
                color: root.error || keyboard.capsLock ? root.ink : root.muted
            }
        }

        // Session and keyboard layout: click to cycle.
        Row {
            x: 240
            y: 992
            spacing: 10
            Repeater {
                model: [["display", "session"], ["keyboard", "layout"]]
                Rectangle {
                    id: pill
                    required property var modelData
                    readonly property bool isLayout: modelData[1] === "layout"
                    visible: !isLayout || root.hasLayouts
                    width: pillLabel.implicitWidth + 62
                    height: 38
                    radius: root.radius
                    color: "transparent"
                    border.color: pillHover.hovered ? root.edgeHover : root.edge
                    border.width: 1
                    Image {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        opacity: .7
                        source: "assets/icons/" + pill.modelData[0] + ".svg"
                        sourceSize.width: 60
                        sourceSize.height: 60
                    }
                    Text {
                        id: pillLabel
                        objectName: "pill-" + pill.modelData[1]
                        x: 38
                        anchors.verticalCenter: parent.verticalCenter
                        text: pill.isLayout ? root.layoutName : root.sessionName
                        font.family: root.sans
                        font.pixelSize: 13
                        color: root.ink
                    }
                    HoverHandler {
                        id: pillHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: {
                            if (pill.isLayout)
                                keyboard.currentLayout = root.step(keyboard.layouts.length, keyboard.currentLayout, 1);
                            else
                                root.sessionIndex = root.step(sessionModel.rowCount(), root.sessionIndex, 1);
                            password.forceActiveFocus();
                        }
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 64
            y: 992
            spacing: 8
            Repeater {
                model: [["sleep", "suspend"], ["restart", "reboot"], ["power", "powerOff"]]
                Rectangle {
                    id: action
                    required property var modelData
                    readonly property bool primary: modelData[1] === "powerOff"
                    visible: modelData[1] === "suspend" ? sddm.canSuspend : modelData[1] === "reboot" ? sddm.canReboot : sddm.canPowerOff
                    width: 38
                    height: 38
                    radius: root.radius
                    color: action.primary ? root.well : "transparent"
                    border.color: actionHover.hovered ? root.edgeHover : root.edge
                    border.width: 1
                    Image {
                        anchors.centerIn: parent
                        width: 17
                        height: 17
                        opacity: action.primary ? 1 : .7
                        source: "assets/icons/" + action.modelData[0] + ".svg"
                        sourceSize.width: 68
                        sourceSize.height: 68
                    }
                    HoverHandler {
                        id: actionHover
                        cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                        onTapped: sddm[action.modelData[1]]()
                    }
                }
            }
        }
    }
}
