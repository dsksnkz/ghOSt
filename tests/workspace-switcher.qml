import QtQuick
import QtTest
import Quickshell

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#000000"
        TestCase {
            id: test
            visible: true
            anchors.fill: parent
            property bool saved: false
            SwitcherScene {
                id: scene
                anchors.fill: parent
                previewMode: true
                property var picks: []
                property int closes: 0
                onChosen: workspace => picks = picks.concat([workspace])
                property var magics: []
                onMagicChosen: special => magics = magics.concat([special])
                onClosed: closes++
            }
            function reopen() {
                scene.open = false;
                wait(250);
                scene.open = true;
                tryCompare(scene, "reveal", 1, 1500);
            }
            function test_switcher() {
                try { check(); }
                catch (error) { console.error("FAIL! switcher: " + error.message + " " + error.stack); throw error; }
            }
            function check() {
                compare(scene.shown, false);
                scene.open = true;
                wait(250);
                verify(scene.shown);
                compare(scene.selected, 1);
                const centre = findChild(scene, "switcher-card-1");
                const next = findChild(scene, "switcher-card-2");
                const previous = findChild(scene, "switcher-card-5");
                tryCompare(scene, "reveal", 1, 1500);
                fuzzyCompare(centre.scale, 592 / 1920, .001);
                fuzzyCompare(next.scale, 423 / 1920, .001);
                fuzzyCompare(next.x - centre.x, 654, .01);
                fuzzyCompare(centre.x - previous.x, 654, .01);
                compare(next.y, centre.y);
                compare(findChild(scene, "switcher-card-3").visible, false);
                compare(findChild(scene, "switcher-number-1").text, "1");
                compare(findChild(scene, "switcher-magic-heading").text, "Magic Workspaces");
                verify(findChild(scene, "switcher-magic-ai") !== null);
                verify(findChild(scene, "switcher-magic-music") !== null);
                const directory = Quickshell.env("GHOST_SWITCHER_CAPTURE_DIR");
                if (directory) {
                    scene.grabToImage(result => saved = result.saveToFile(directory + "/switcher.png"));
                    tryCompare(test, "saved", true, 2000);
                }
                // The cards themselves must travel, not just the selection.
                keyClick(Qt.Key_Tab);
                compare(scene.selected, 2);
                tryCompare(scene, "position", scene.target, 1500);
                fuzzyCompare(findChild(scene, "switcher-card-2").offset, 0, .001);
                fuzzyCompare(findChild(scene, "switcher-card-2").scale, 592 / 1920, .001);
                keyClick(Qt.Key_Backtab);
                keyClick(Qt.Key_Left);
                compare(scene.selected, 5);
                keyClick(Qt.Key_Right);
                compare(scene.selected, 1);
                wait(250);
                scene.scroll(60);
                compare(scene.selected, 1);
                scene.scroll(60);
                compare(scene.selected, 5);
                scene.scroll(-120);
                compare(scene.selected, 1);
                wait(450);
                keyClick(Qt.Key_Escape);
                compare(scene.closes, 1);
                compare(scene.picks.length, 0);
                reopen();
                keyClick(Qt.Key_Right);
                keyClick(Qt.Key_Return);
                compare(scene.picks.join(), "2");
                tryCompare(scene, "expansion", 1, 1000);
                tryCompare(scene, "closes", 2, 1000);
                compare(scene.shown, false);
                reopen();
                compare(scene.position, scene.target);
                scene.scroll(-120);
                tryCompare(scene, "position", scene.target, 1500);
                scene.scroll(120);
                tryCompare(scene, "position", scene.target, 1500);
                keyRelease(Qt.Key_Super_L);
                compare(scene.superHeld, false);
                compare(scene.picks.join(), "2");
                keyClick(Qt.Key_Right);
                compare(scene.picks.join(), "2");
                keyPress(Qt.Key_Super_L);
                keyRelease(Qt.Key_Super_L);
                compare(scene.picks.join(), "2,2");
                tryCompare(scene, "closes", 3, 1000);
                reopen();
                compare(scene.expansion, 0);
                const side = findChild(scene, "switcher-card-5");
                mouseClick(side, side.width / 2, side.height / 2);
                compare(scene.picks.join(), "2,2,5");
                // The clicked side card must start zooming at once, not jump near the centre.
                verify(side.chosen);
                tryVerify(() => scene.expansion > .2 && side.scale > 423 / 1920 + .05, 300);
                verify(side.opacity > .9);
                tryCompare(scene, "closes", 4, 1000);
                reopen();
                const music = findChild(scene, "switcher-magic-music");
                mouseClick(music, music.width / 2, music.height / 2);
                compare(scene.magics.join(), "music");
                reopen();
                keyClick(Qt.Key_Down);
                keyClick(Qt.Key_Return);
                compare(scene.magics.join(), "music,ai");
                scene.open = false;
                tryCompare(scene, "shown", false, 1500);
                console.info("PASS: switcher geometry, wrap, keyboard, click, cancel and expansion");
            }
        }
    }
}
