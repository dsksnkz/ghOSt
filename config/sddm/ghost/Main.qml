import QtQuick

// ghOSt SDDM greeter (Qt 6, SDDM 0.21+). Session list on the left, profile picture
// and password in the centre, the ghost outline on the right.
// Uses only SDDM's context objects: sddm, userModel, sessionModel, keyboard, config.
Item {
    id: root
    width: 1920
    height: 1080

    readonly property string sans: "Adwaita Sans"
    readonly property color field: "#171717"
    readonly property color ink: "#ffffff"
    readonly property color muted: "#8c8c8a"
    // Content is drawn on a 1920 × 1080 plane and scaled to fit; the
    // background always fills the whole screen.
    readonly property real fit: Math.min(width / 1920, height / 1080)

    // SDDM user roles: 257 name, 258 real name, 260 icon, 261 needs password.
    property int userIndex: Math.max(0, userModel.lastIndex)
    readonly property string userName: userModel.data(userModel.index(userIndex, 0), 257) || ""
    readonly property string userIcon: userModel.data(userModel.index(userIndex, 0), 260) || ""
    // SDDM session role 260: display name.
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    readonly property int sessionCount: sessionModel.rowCount()
    readonly property string sessionName: sessionModel.data(sessionModel.index(sessionIndex, 0), 260) || ""
    property real sessionPosition: sessionIndex
    Behavior on sessionPosition {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    property string error: ""
    property bool keyboardOpen: false
    property bool busy: false

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
    function selectSession(index) {
        sessionIndex = Math.max(0, Math.min(sessionCount - 1, index));
        password.forceActiveFocus();
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

    Rectangle {
        anchors.fill: parent
        color: root.field
    }

    Item {
        id: plane
        width: 1920
        height: 1080
        anchors.centerIn: parent
        scale: root.fit

        Image {
            objectName: "ghost"
            visible: root.setting("watermark", "true") !== "false"
            x: 1508
            y: 210
            width: 690
            height: 690
            rotation: -8
            source: "assets/ghost-outline.svg"
            sourceSize.width: 1380
            sourceSize.height: 1380
        }

        // Session list: the selected row sits beside the arrow, neighbours fade out.
        Item {
            objectName: "sessions"
            x: 120
            y: 424
            width: 340
            height: 240
            clip: true
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => root.selectSession(root.sessionIndex + (event.angleDelta.y > 0 ? -1 : 1))
            }
            Canvas {
                x: 26
                y: 114
                width: 12
                height: 12
                onPaint: {
                    const context = getContext("2d");
                    context.fillStyle = "#8c8c8c";
                    context.beginPath();
                    context.moveTo(0, 0);
                    context.lineTo(12, 6);
                    context.lineTo(0, 12);
                    context.closePath();
                    context.fill();
                }
            }
            Repeater {
                model: root.sessionCount
                Text {
                    required property int index
                    readonly property real distance: Math.abs(index - root.sessionPosition)
                    objectName: "session-" + index
                    x: 74
                    y: 120 - height / 2 + (index - root.sessionPosition) * 24
                    visible: opacity > 0
                    opacity: distance < 1 ? 1 - .62 * distance : Math.max(0, .38 - .2 * (distance - 1) - (distance > 2 ? .18 * (distance - 2) : 0))
                    text: sessionModel.data(sessionModel.index(index, 0), 260) || ""
                    font.family: root.sans
                    font.pixelSize: 14
                    color: root.ink
                    TapHandler {
                        onTapped: root.selectSession(parent.index)
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        // Profile picture chosen in ghOSt Settings; click to switch when several users exist.
        Rectangle {
            objectName: "picture"
            x: 893
            y: 430
            width: 134
            height: 134
            color: "#d9d9d9"
            radius: 12
            Image {
                objectName: "picture-image"
                anchors.fill: parent
                source: root.userIcon
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 268
                sourceSize.height: 268
                asynchronous: true
            }
            // Rounds the picture without an effects module: a field-coloured frame
            // whose inner radius is the picture's radius.
            Rectangle {
                anchors.fill: parent
                anchors.margins: -10
                radius: parent.radius + 10
                color: "transparent"
                border.color: root.field
                border.width: 10
            }
            TapHandler {
                enabled: userModel.count > 1
                onTapped: {
                    root.userIndex = (root.userIndex + 1) % userModel.count;
                    root.error = "";
                    password.text = "";
                    password.forceActiveFocus();
                }
            }
        }

        Item {
            id: shaker
            x: 890
            y: 608
            width: 140
            height: 24
            readonly property real restX: 890
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shaker; property: "x"; to: shaker.restX - 8; duration: 50 }
                NumberAnimation { target: shaker; property: "x"; to: shaker.restX + 7; duration: 60 }
                NumberAnimation { target: shaker; property: "x"; to: shaker.restX - 4; duration: 60 }
                NumberAnimation { target: shaker; property: "x"; to: shaker.restX; duration: 70 }
            }
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#272727"
                border.width: 1
                border.color: root.error ? "#8c8c8c" : "#3b3b3b"
                opacity: root.busy ? .5 : 1
                TextInput {
                    id: password
                    objectName: "password"
                    anchors.fill: parent
                    focus: true
                    echoMode: TextInput.Password
                    color: "transparent"
                    selectionColor: "transparent"
                    selectedTextColor: "transparent"
                    cursorDelegate: Item {}
                    enabled: !root.busy
                    Keys.onReturnPressed: root.login()
                    Keys.onEnterPressed: root.login()
                    Keys.onUpPressed: root.selectSession(root.sessionIndex - 1)
                    Keys.onDownPressed: root.selectSession(root.sessionIndex + 1)
                    onTextEdited: root.error = ""
                }
                Row {
                    objectName: "password-dots"
                    readonly property int shown: Math.min(password.text.length, 14)
                    anchors.centerIn: parent
                    spacing: shown > 1 ? Math.min(8, (124 - shown * 8) / (shown - 1)) : 0
                    Repeater {
                        model: parent.shown
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: "#e6e6e6"
                        }
                    }
                }
            }
        }

        Rectangle {
            objectName: "keyboard-toggle"
            visible: keyboardLoader.status === Loader.Ready
            x: 1040
            y: 606
            width: 28
            height: 28
            radius: 6
            color: root.keyboardOpen ? root.ink : keyHover.hovered ? "#272727" : "transparent"
            Image {
                anchors.centerIn: parent
                width: 20
                height: 20
                opacity: root.keyboardOpen ? 1 : .75
                source: "assets/icons/" + (root.keyboardOpen ? "keyboard-black" : "keyboard") + ".svg"
                sourceSize.width: 80
                sourceSize.height: 80
            }
            HoverHandler {
                id: keyHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: {
                    root.keyboardOpen = !root.keyboardOpen;
                    password.forceActiveFocus();
                }
            }
        }

        Text {
            objectName: "status"
            x: 760
            y: 644
            width: 400
            horizontalAlignment: Text.AlignHCenter
            text: root.error ? root.error : keyboard.capsLock ? "Caps Lock is on" : ""
            font.family: root.sans
            font.pixelSize: 13
            color: root.muted
        }
    }

    // Loaded separately so a missing virtual-keyboard module cannot break the theme.
    Loader {
        id: keyboardLoader
        source: "KeyboardPanel.qml"
        width: Math.min(parent.width, 1200 * root.fit)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - (item ? item.height : 0)
        z: 10
        onLoaded: item.open = Qt.binding(() => root.keyboardOpen)
    }
}
