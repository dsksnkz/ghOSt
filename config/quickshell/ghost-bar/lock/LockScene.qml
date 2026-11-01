import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import ".."

// Visual component only. The production entry owns session lock and PAM.
FocusScope {
    id: scene
    property bool reducedMotion: false
    property bool credentialsVisible: false
    property bool busy: false
    property string error: ""
    property date now: new Date()
    property url wallpaper
    property url picture: Qt.resolvedUrl("../artwork/profile.jpg")
    property string userName: ""
    property bool leaving: false
    property real entrance: 0
    property real reveal: credentialsVisible ? 1 : 0
    property real exit: 0
    signal wakeRequested
    signal sleepRequested
    signal activity
    signal submitted(string response)
    signal exited

    function wake(text) {
        if (leaving)
            return;
        wakeRequested();
        activity();
        password.forceActiveFocus();
        if (text)
            password.insert(password.cursorPosition, text);
    }
    function rest() {
        if (leaving)
            return;
        password.clear();
        scene.forceActiveFocus();
        sleepRequested();
    }
    function restartIdle() {
        if (credentialsVisible && !busy && !leaving)
            idle.restart();
        else
            idle.stop();
    }
    function submit() {
        if (busy || leaving || password.text.length === 0)
            return;
        const response = password.text;
        password.clear();
        submitted(response);
    }
    onLeavingChanged: if (leaving) {
        idle.stop();
        exitMotion.restart();
    }
    onCredentialsVisibleChanged: {
        restartIdle();
        if (credentialsVisible)
            password.forceActiveFocus();
    }
    onBusyChanged: restartIdle()
    onErrorChanged: if (error)
        shake.restart()
    Component.onCompleted: {
        forceActiveFocus();
        entranceMotion.start();
    }
    Timer {
        id: idle
        objectName: "lock-idle"
        interval: 15000
        onTriggered: scene.rest()
    }
    NumberAnimation {
        id: entranceMotion
        target: scene
        property: "entrance"
        to: 1
        duration: scene.reducedMotion ? 0 : 900
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.16, 1, 0.3, 1, 1, 1]
    }
    Behavior on reveal {
        NumberAnimation {
            duration: scene.reducedMotion ? 0 : 420
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
    }
    NumberAnimation {
        id: exitMotion
        target: scene
        property: "exit"
        to: 1
        duration: scene.reducedMotion ? 0 : 380
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
        onFinished: scene.exited()
    }
    SequentialAnimation {
        id: shake
        loops: 1
        NumberAnimation { target: passwordFrame; property: "shift"; to: -10; duration: 50 }
        NumberAnimation { target: passwordFrame; property: "shift"; to: 8; duration: 70 }
        NumberAnimation { target: passwordFrame; property: "shift"; to: -5; duration: 60 }
        NumberAnimation { target: passwordFrame; property: "shift"; to: 0; duration: 70 }
    }

    Rectangle {
        anchors.fill: parent
        color: "#0b0b0c"
    }
    // The wallpaper settles in on lock and returns to its exact desktop size on the way out.
    Item {
        anchors.fill: parent
        clip: true
        scale: 1
        Image {
            id: sharp
            objectName: "lock-wallpaper"
            anchors.fill: parent
            source: scene.wallpaper
            sourceSize.width: scene.width
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            scale: (1.05 - .05 * scene.entrance) * (1 + .03 * scene.reveal * (1 - scene.exit))
            opacity: status === Image.Ready ? 1 : 0
        }
        // One blurred copy, rendered once; waking only fades it in.
        Image {
            anchors.fill: parent
            source: scene.wallpaper
            sourceSize.width: scene.width
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            scale: sharp.scale
            visible: scene.reveal * (1 - scene.exit) > .001
            opacity: scene.reveal * (1 - scene.exit)
            layer.enabled: visible
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: .75
                blurMax: 40
            }
        }
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: (.14 + .24 * scene.reveal) * (1 - scene.exit)
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: scene.credentialsVisible ? scene.activity() : scene.wake("")
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            scene.rest();
            event.accepted = true;
            return;
        }
        scene.activity();
        if (!scene.credentialsVisible && (event.text.length > 0 || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            scene.wake(event.text.trim());
            event.accepted = true;
        }
    }

    Column {
        id: time
        objectName: "lock-clock"
        width: parent.width
        y: scene.height * .13 + 36 * (1 - scene.entrance) - scene.height * .03 * scene.reveal - 48 * scene.exit
        opacity: scene.entrance * (1 - scene.exit)
        spacing: 2
        Text {
            objectName: "lock-date"
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDateTime(scene.now, "dddd, d MMMM")
            font.family: Theme.font
            font.pixelSize: Math.round(Math.min(26, scene.width / 44))
            font.weight: Theme.mediumWeight
            color: "#ffffff"
        }
        Text {
            objectName: "lock-time"
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDateTime(scene.now, "HH:mm")
            font.family: Theme.font
            font.pixelSize: Math.round(Math.min(148, scene.width / 7.5))
            font.weight: Font.DemiBold
            font.letterSpacing: -2
            color: "#ffffff"
            scale: 1 - .1 * scene.reveal
            transformOrigin: Item.Top
        }
    }

    Column {
        id: credentials
        objectName: "lock-credentials"
        width: Math.min(280, scene.width - 48)
        x: (scene.width - width) / 2
        y: scene.height * .62 + 28 * (1 - scene.reveal) + 28 * scene.exit
        spacing: 14
        opacity: scene.reveal * (1 - scene.exit)
        visible: opacity > .001
        G2Image {
            objectName: "lock-picture"
            anchors.horizontalCenter: parent.horizontalCenter
            width: 76
            height: 76
            radius: 38
            source: scene.picture
        }
        Text {
            objectName: "lock-user"
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: scene.userName
            visible: text.length > 0
            font.family: Theme.font
            font.pixelSize: 16
            font.weight: Theme.mediumWeight
            color: "#ffffff"
        }
        Item {
            id: passwordFrame
            property real shift: 0
            width: parent.width
            height: 40
            TextField {
                id: password
                objectName: "lock-password"
                x: passwordFrame.shift
                width: parent.width
                height: parent.height
                enabled: scene.credentialsVisible && !scene.busy && !scene.leaving
                opacity: scene.busy ? .6 : 1
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                placeholderText: "Enter Password"
                placeholderTextColor: "#d4d4d4"
                color: "#ffffff"
                font.family: Theme.font
                font.pixelSize: 15
                horizontalAlignment: TextInput.AlignHCenter
                leftPadding: 18
                rightPadding: 18
                selectByMouse: false
                background: Rectangle {
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, .16)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, password.activeFocus ? .38 : .2)
                }
                onAccepted: scene.submit()
                onTextEdited: scene.activity()
                Keys.onPressed: event => {
                    scene.activity();
                    if (event.key === Qt.Key_Escape) {
                        scene.rest();
                        event.accepted = true;
                    }
                }
            }
        }
        Text {
            objectName: "lock-message"
            width: parent.width
            height: 18
            horizontalAlignment: Text.AlignHCenter
            text: scene.error
            wrapMode: Text.NoWrap
            font.family: Theme.font
            font.pixelSize: 13
            color: "#ffffff"
        }
    }
}
