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
    property real drop: 0
    property real reveal: credentialsVisible ? 1 : 0
    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"
    signal wakeRequested
    signal sleepRequested
    signal activity
    signal submitted(string response)

    function wake(text) {
        wakeRequested();
        activity();
        password.forceActiveFocus();
        if (text)
            password.insert(password.cursorPosition, text);
    }
    function rest() {
        password.clear();
        password.focus = false;
        scene.forceActiveFocus();
        sleepRequested();
    }
    function restartIdle() {
        if (credentialsVisible && !busy)
            idle.restart();
        else
            idle.stop();
    }
    onCredentialsVisibleChanged: restartIdle()
    onBusyChanged: restartIdle()
    Timer {
        id: idle
        objectName: "lock-idle"
        interval: 10000
        onTriggered: scene.rest()
    }
    function submit() {
        if (busy || password.text.length === 0)
            return;
        const response = password.text;
        password.clear();
        submitted(response);
    }
    Component.onCompleted: {
        forceActiveFocus();
        descent.start();
    }
    onReducedMotionChanged: if (reducedMotion)
        descent.complete()
    NumberAnimation {
        id: descent
        target: scene
        property: "drop"
        to: 1
        duration: scene.reducedMotion ? 0 : 800
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.2, 0.75, 0.25, 1, 1, 1]
    }
    Behavior on reveal {
        NumberAnimation {
            duration: scene.reducedMotion ? 0 : 420
            easing.type: Easing.InOutCubic
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "#171717"
    }
    Item {
        anchors.fill: parent
        layer.enabled: scene.reveal > 0
        // Blur needs fewer pixels than the sharp slat view. Keep the sharp
        // renderer full-resolution and halve only the blur render target.
        layer.textureSize: Qt.size(Math.ceil(width / 2), Math.ceil(height / 2))
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 16
            blur: scene.reveal * 0.8
        }
        Blinds {
            width: parent.width
            height: parent.height
            drop: scene.drop
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: scene.rest()
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            scene.rest();
            event.accepted = true;
            return;
        }
        scene.activity();
        if (!scene.credentialsVisible) {
            if (event.text.length > 0 || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                scene.wake(event.text);
                event.accepted = true;
            }
        }
    }
    Column {
        id: credentials
        width: Math.min(340, scene.width - 48)
        anchors.centerIn: parent
        spacing: 28
        opacity: scene.reveal
        layer.enabled: scene.reveal < 1 && scene.reveal > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 24
            blur: 1 - scene.reveal
        }
        Text {
            width: parent.width
            text: Qt.formatDateTime(scene.now, "HH:mm")
            horizontalAlignment: Text.AlignHCenter
            font.family: scene.fontFamily
            font.pixelSize: Math.min(68, scene.width / 9)
            font.weight: Font.Light
            color: "#ffffff"
        }
        TextField {
            id: password
            objectName: "lock-password"
            width: parent.width
            height: 52
            visible: scene.credentialsVisible
            enabled: !scene.busy
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            placeholderText: "Password"
            placeholderTextColor: "#b8b8b8"
            color: "#ffffff"
            font.family: scene.fontFamily
            font.pixelSize: 16
            leftPadding: 18
            rightPadding: 18
            selectByMouse: false
            persistentSelection: false
            background: G2Surface {
                radius: 15
                smoothing: 0.6
                color: "#242424"
                border.width: 1
                border.color: password.activeFocus ? "#9c9c9c" : "#555555"
            }
            onAccepted: scene.submit()
            onTextEdited: scene.activity()
            TapHandler {
                onPressedChanged: if (pressed) scene.activity()
            }
            Keys.onPressed: event => {
                scene.activity();
                if (event.key === Qt.Key_Escape) {
                    scene.rest();
                    event.accepted = true;
                }
            }
        }
        Text {
            width: parent.width
            text: scene.busy ? "Checking…" : scene.error
            visible: text.length > 0
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.family: scene.fontFamily
            font.pixelSize: 12
            color: "#dddddd"
        }
    }
}
