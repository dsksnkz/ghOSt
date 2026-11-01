import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.Pam
import "lock"

// No WlSessionLock or real PamContext is instantiated in this harness.
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 1920
        implicitHeight: 1080
        TestCase {
            id: test
            visible: true
            width: 1920
            height: 1080
            property int accepts: 0
            property int submissions: 0
            property int lefts: 0
            property bool saved: false
            function capture(name) {
                const directory = Quickshell.env("GHOST_LOCK_CAPTURE_DIR");
                if (!directory)
                    return;
                saved = false;
                scene.grabToImage(result => {
                    saved = result.saveToFile(directory + "/" + name + ".png");
                }, Qt.size(1920, 1080));
                tryCompare(test, "saved", true, 1500);
            }
            function test_lock() {
                try { check(); }
                catch (error) { console.error("FAIL! lock: " + error.message + " " + error.stack); throw error; }
            }
            function check() {
                // Entrance: the clock rises in by itself, with no password showing.
                tryCompare(scene, "entrance", 1, 1500);
                compare(findChild(scene, "lock-time").text, "21:30");
                compare(findChild(scene, "lock-date").text, Qt.formatDateTime(new Date(2026, 9, 9), "dddd, d MMMM"));
                compare(findChild(scene, "lock-credentials").visible, false);
                capture("clock");

                // The first key wakes it and becomes the password's first character.
                scene.forceActiveFocus();
                keyClick(Qt.Key_A);
                compare(scene.credentialsVisible, true);
                const field = findChild(scene, "lock-password");
                compare(field.text, "a");
                compare(field.echoMode, TextInput.Password);
                tryCompare(scene, "reveal", 1, 1000);
                compare(findChild(scene, "lock-user").text, "fixture");
                capture("password");
                keyClick(Qt.Key_Return);
                compare(submissions, 1);
                compare(field.text, "");

                // A click wakes, Escape rests and clears.
                keyClick(Qt.Key_B);
                keyClick(Qt.Key_Escape);
                compare(scene.credentialsVisible, false);
                compare(field.text, "");
                tryCompare(scene, "reveal", 0, 1000);
                mouseClick(scene, 10, 10);
                compare(scene.credentialsVisible, true);

                // Wrong password keeps the field usable.
                scene.error = "Incorrect password";
                capture("error");
                compare(findChild(scene, "lock-message").text, "Incorrect password");
                wait(300);
                verify(field.enabled);
                scene.error = "";

                // Idle returns to the clock, but never while checking a password.
                const idle = findChild(scene, "lock-idle");
                compare(idle.interval, 15000);
                idle.interval = 120;
                scene.busy = true;
                wait(180);
                compare(scene.credentialsVisible, true);
                verify(!field.enabled);
                scene.busy = false;
                wait(180);
                compare(scene.credentialsVisible, false);
                idle.interval = 15000;

                // Mocked PAM: failures never accept, and success accepts once.
                backend.allowStart = false;
                verify(!auth.submit("fixture"));
                compare(auth.pendingResponse, "");
                compare(auth.busy, false);
                backend.allowStart = true;
                verify(auth.submit("fixture"));
                verify(!auth.submit("duplicate"));
                backend.responseRequired = true;
                auth.respondToPrompt();
                compare(auth.pendingResponse, "");
                compare(backend.responses, 1);
                backend.active = false;
                auth.complete(PamResult.Failed);
                compare(auth.error, "Incorrect password");
                auth.complete(PamResult.Error);
                auth.complete(PamResult.MaxTries);
                compare(accepts, 0);
                compare(auth.authenticated, false);
                verify(auth.submit("fixture"));
                backend.active = false;
                auth.complete(PamResult.Success);
                compare(accepts, 1);
                verify(auth.authenticated);
                verify(!auth.submit("again"));

                // Leaving animates once and always reports back, even in the middle of waking.
                scene.credentialsVisible = true;
                scene.leaving = true;
                verify(!field.enabled);
                tryCompare(test, "lefts", 1, 1500);
                compare(scene.exit, 1);
                compare(findChild(scene, "lock-credentials").visible, false);
                compare(findChild(scene, "lock-clock").opacity, 0);
                wait(100);
                compare(lefts, 1);

                // Reduced motion reaches the end immediately.
                scene.leaving = false;
                scene.exit = 0;
                scene.reducedMotion = true;
                scene.leaving = true;
                tryCompare(test, "lefts", 2, 300);
                console.info("PASS: lock clock, first key, masked submit, idle, PAM failures and success, exit always completes");
            }
            QtObject {
                id: backend
                property bool active: false
                property bool responseRequired: false
                property bool allowStart: true
                property int responses: 0
                function start() { active = allowStart; return allowStart; }
                function respond(response) { responses++; responseRequired = false; }
            }
            LockAuth { id: auth; context: backend; onAccepted: test.accepts++ }
            LockScene {
                id: scene
                anchors.fill: parent
                now: new Date(2026, 9, 9, 21, 30)
                userName: "fixture"
                wallpaper: Quickshell.env("GHOST_LOCK_WALLPAPER") ? "file://" + Quickshell.env("GHOST_LOCK_WALLPAPER") : ""
                onWakeRequested: credentialsVisible = true
                onSleepRequested: credentialsVisible = false
                onActivity: restartIdle()
                onSubmitted: test.submissions++
                onExited: test.lefts++
            }
        }
    }
}
