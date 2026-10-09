import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.Pam
import "lock"

// No WlSessionLock or real PamContext is instantiated in this harness.
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 1024
        implicitHeight: 576
        TestCase {
            id: test
            visible: true
            width: 1024
            height: 576
            property int accepts: 0
            property int submissions: 0
            property bool saved: false
            function capture(name) {
                const directory = Quickshell.env("GHOST_LOCK_CAPTURE_DIR");
                if (!directory)
                    return;
                saved = false;
                scene.grabToImage(result => {
                    saved = result.saveToFile(directory + "/" + name + ".png");
                });
                tryCompare(test, "saved", true, 1500);
            }
            function test_lock() {
                wait(100);
                verify(scene.drop > 0 && scene.drop < 1);
                capture("descending");
                wait(850);
                compare(scene.drop, 1);
                capture("blinds");
                scene.forceActiveFocus();
                keyClick(Qt.Key_A);
                compare(scene.credentialsVisible, true);
                const field = findChild(scene, "lock-password");
                compare(field.text, "a");
                wait(450);
                compare(scene.reveal, 1);
                verify(field.visible);
                compare(field.width, 340);
                compare(field.height, 52);
                keyClick(Qt.Key_Return);
                compare(submissions, 1);
                compare(field.text, "");
                capture("clock-password");

                backend.allowStart = false;
                verify(!auth.submit("fixture"));
                compare(auth.pendingResponse, "");
                compare(auth.busy, false);
                compare(accepts, 0);
                backend.allowStart = true;
                verify(auth.submit("fixture"));
                verify(!auth.submit("duplicate"));
                backend.responseRequired = true;
                auth.respondToPrompt();
                compare(auth.pendingResponse, "");
                compare(backend.responses, 1);
                backend.active = false;
                auth.complete(PamResult.Failed);
                compare(accepts, 0);
                compare(auth.authenticated, false);
                auth.complete(PamResult.Error);
                compare(accepts, 0);
                auth.complete(PamResult.MaxTries);
                compare(accepts, 0);
                verify(auth.submit("fixture"));
                backend.active = false;
                auth.complete(PamResult.Success);
                compare(accepts, 1);
                verify(auth.authenticated);
                verify(!auth.submit("again"));
                compare(auth.pendingResponse, "");

                scene.visible = false;
                blinds.visible = true;
                blinds.opening = 0.5;
                wait(30);
                compare(blinds.y, 0);
                verify(blinds.count > 1);
                saved = false;
                const directory = Quickshell.env("GHOST_LOCK_CAPTURE_DIR");
                if (directory) {
                    blinds.grabToImage(result => saved = result.saveToFile(directory + "/rotating.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                blinds.opening = 1;
                compare(blinds.y, 0);
                scene.visible = true;
                blinds.visible = false;
                scene.reducedMotion = true;
                scene.credentialsVisible = false;
                wait(20);
                compare(scene.reveal, 0);
                scene.credentialsVisible = true;
                wait(20);
                compare(scene.reveal, 1);
                console.info("PASS: lock descent, first key, masked submit, PAM failures/success, stationary rotation and reduced motion");
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
                onWakeRequested: credentialsVisible = true
                onSubmitted: test.submissions++
            }
            Blinds { id: blinds; visible: false; width: parent.width; height: parent.height }
        }
    }
}
