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
                scene.trackCursor(scene.width, scene.height);
                wait(130);
                compare(scene.cursorTilt, 30);
                scene.trackCursor(0, 0);
                wait(130);
                compare(scene.cursorTilt, -30);
                scene.pointerTilt = 0;
                mouseClick(scene, 10, 10);
                compare(scene.credentialsVisible, false);
                if (Quickshell.env("GHOST_LOCK_EXPECT_3D"))
                    tryCompare(blinds, "uses3D", true, 2000);
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
                compare(scene.cursorTilt, 0);
                const border = findChild(scene, "lock-password-border");
                compare(border.color, "#00000000");
                compare(border.border.width, 1);
                keyClick(Qt.Key_Return);
                compare(submissions, 1);
                compare(field.text, "");
                capture("clock-password");
                const column = findChild(scene, "lock-credentials");
                const columnY = column.y;
                const columnHeight = column.height;
                scene.pointerTilt = 30;
                mouseClick(scene, 10, 10);
                compare(scene.credentialsVisible, false);
                compare(field.text, "");
                wait(110);
                compare(column.y, columnY);
                compare(column.height, columnHeight);
                verify(Math.abs(scene.cursorTilt) > 0 && Math.abs(scene.cursorTilt) < 30);
                capture("cancel-blur");
                keyClick(Qt.Key_B);
                compare(scene.credentialsVisible, true);
                const idle = findChild(scene, "lock-idle");
                compare(idle.interval, 10000);
                idle.interval = 120;
                scene.busy = true;
                wait(180);
                compare(scene.credentialsVisible, true);
                scene.busy = false;
                wait(180);
                compare(scene.credentialsVisible, false);
                compare(field.text, "");
                idle.interval = 10000;
                wait(450);

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
                wait(100);
                blinds.opening = 0.5;
                wait(250);
                compare(blinds.renderedOpening, 0.5);
                waitForRendering(blinds);
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
                onSleepRequested: credentialsVisible = false
                onActivity: restartIdle()
                onSubmitted: test.submissions++
            }
            Blinds { id: blinds; force3D: !!Quickshell.env("GHOST_LOCK_EXPECT_3D"); visible: false; width: parent.width; height: parent.height }
        }
    }
}
