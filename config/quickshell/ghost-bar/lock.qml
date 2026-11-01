//@ pragma ShellId ghost-lock
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "lock"

ShellRoot {
    id: root
    property bool credentialsVisible: false
    property bool reducedMotion: false
    property url wallpaper
    property url picture: Qt.resolvedUrl("artwork/profile.jpg")
    signal activity

    // PAM is the only source of authorization; no unlock IPC or visual test mode.
    function release() {
        if (!auth.authenticated)
            return;
        unlockDeadline.stop();
        lock.locked = false;
        quitDelay.start();
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/ghost/settings.json"
        onLoaded: {
            try {
                const settings = JSON.parse(text());
                root.reducedMotion = settings.reducedMotion === true;
                if (settings.wallpaper)
                    root.wallpaper = "file://" + settings.wallpaper;
                if (settings.profilePicture)
                    root.picture = settings.profilePicture;
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
        onAccepted: unlockDeadline.start()
    }
    // A correct password always unlocks, whatever happens to the exit animation.
    Timer {
        id: unlockDeadline
        interval: 800
        onTriggered: root.release()
    }
    // Give the compositor a moment to process the unlock before this client exits.
    Timer {
        id: quitDelay
        interval: 150
        onTriggered: Qt.quit()
    }
    WlSessionLock {
        id: lock
        locked: true
        WlSessionLockSurface {
            color: "#0b0b0c"
            LockScene {
                id: lockScene
                anchors.fill: parent
                reducedMotion: root.reducedMotion
                credentialsVisible: root.credentialsVisible
                busy: auth.busy
                error: auth.error
                leaving: auth.authenticated
                now: clock.date
                wallpaper: root.wallpaper
                picture: root.picture
                userName: Quickshell.env("USER") || ""
                onWakeRequested: root.credentialsVisible = true
                onSleepRequested: root.credentialsVisible = false
                onActivity: root.activity()
                onExited: root.release()
                onSubmitted: response => auth.submit(response)
                Connections {
                    target: root
                    function onActivity() { lockScene.restartIdle(); }
                }
            }
        }
    }
}
