import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root
    property bool credentialsVisible: false
    property bool reducedMotion: false
    property var preparedScreens: []
    property var finishedScreens: []

    // PAM is the only source of authorization; no unlock IPC or visual test mode.
    function releaseWhenPrepared() {
        if (auth.authenticated && lock.secure && Quickshell.screens.every(screen => preparedScreens.includes(screen.name)))
            lock.locked = false;
    }
    function finishWhenComplete() {
        if (auth.authenticated && !lock.locked && Quickshell.screens.every(screen => finishedScreens.includes(screen.name)))
            Qt.quit();
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/ghost/settings.json"
        onLoaded: {
            try {
                root.reducedMotion = JSON.parse(text()).reducedMotion === true;
            } catch (error) {
                root.reducedMotion = false;
            }
        }
    }
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    PamContext {
        id: pam
        config: "hyprlock"
        onPamMessage: auth.respondToPrompt()
        onCompleted: result => auth.complete(result)
    }
    LockAuth {
        id: auth
        context: pam
    }
    WlSessionLock {
        id: lock
        locked: true
        WlSessionLockSurface {
            color: "#171717"
            LockScene {
                anchors.fill: parent
                reducedMotion: root.reducedMotion
                credentialsVisible: root.credentialsVisible
                busy: auth.busy || !lock.secure
                error: auth.error
                now: clock.date
                onWakeRequested: root.credentialsVisible = true
                onSubmitted: response => auth.submit(response)
            }
        }
    }
    Variants {
        model: auth.authenticated ? Quickshell.screens : []
        delegate: ExitOverlay {
            required property var modelData
            screen: modelData
            reducedMotion: root.reducedMotion
            begin: !lock.locked
            onPrepared: {
                root.preparedScreens = root.preparedScreens.concat(modelData.name);
                root.releaseWhenPrepared();
            }
            onFinished: {
                root.finishedScreens = root.finishedScreens.concat(modelData.name);
                root.finishWhenComplete();
            }
        }
    }
    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.releaseWhenPrepared();
            root.finishWhenComplete();
        }
    }
}
