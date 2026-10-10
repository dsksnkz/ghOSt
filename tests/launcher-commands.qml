import QtQuick
import QtTest
import Quickshell

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 560
        implicitHeight: 328
        color: "#191919"
        TestCase {
            id: test
            visible: true
            anchors.fill: parent
            property bool saved: false
            property int closes: 0
            G2Surface {
                anchors.fill: parent
                color: "#191919"
                radius: 22
                smoothing: 0.6
                border.width: 1
                border.color: "#333333"
            }
            Launcher {
                id: launcher
                anchors.fill: parent
                anchors.margins: 16
                previewMode: true
                onCloseRequested: test.closes++
            }
            function test_commands() {
                wait(100);
                launcher.query = ">";
                compare(launcher.results.length, 0);
                launcher.query = '> printf "%s\\n" "hello ghOSt" | sort';
                compare(launcher.results.length, 1);
                compare(launcher.results[0].terminalCommand, 'printf "%s\\n" "hello ghOSt" | sort');
                const previousPins = JSON.stringify(launcher.pins);
                launcher.pin(launcher.results[0]);
                compare(JSON.stringify(launcher.pins), previousPins);
                launcher.focusSearch();
                keyClick(Qt.Key_Return);
                compare(launcher.lastRequest, "ghost-terminal-command");
                const directory = Quickshell.env("GHOST_LAUNCHER_CAPTURE_DIR");
                if (directory) {
                    test.grabToImage(result => saved = result.saveToFile(directory + "/terminal-mode.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                launcher.query = "kitty";
                compare(launcher.commandMode, false);
                verify(launcher.results.every(entry => !entry.terminalCommand));
                launcher.beginSession();
                compare(launcher.query, "");
                compare(launcher.lastRequest, "");
                wait(250);
                const list = findChild(launcher, "launcher-list");
                const outline = findChild(launcher, "launcher-selection");
                verify(launcher.results.length > 1);
                launcher.focusSearch();
                keyClick(Qt.Key_Down);
                compare(list.currentIndex, 1);
                wait(70);
                if (!Theme.reducedMotion)
                    verify(outline.y > 0 && outline.y < 56);
                wait(240);
                compare(outline.y, 56);
                compare(outline.color, "#00000000");
                compare(outline.border.width, 1);
                compare(list.height, 4 * 48 + 3 * 8);
                verify(launcher.height - list.y - list.height >= 16);
                if (directory) {
                    saved = false;
                    test.grabToImage(result => saved = result.saveToFile(directory + "/four-apps.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                keyClick(Qt.Key_Up);
                compare(list.currentIndex, 0);
                wait(250);
                compare(outline.y, 0);
                verify(launcher.results.length > 6);
                for (let i = 0; i < 3; i++) keyClick(Qt.Key_Down);
                wait(250);
                compare(list.currentIndex, 3);
                compare(list.contentY, 0);
                keyClick(Qt.Key_Down);
                compare(list.currentIndex, 4);
                compare(list.contentY, 0);
                wait(70);
                if (!Theme.reducedMotion) {
                    verify(list.contentY > 0 && list.contentY < 56);
                    compare(Math.round(outline.y - list.contentY), 168);
                }
                wait(250);
                compare(list.contentY, 56);
                keyClick(Qt.Key_Down);
                wait(40);
                keyClick(Qt.Key_Down);
                wait(260);
                compare(list.currentIndex, 6);
                compare(list.contentY, 168);
                for (let i = 0; i < 4; i++) keyClick(Qt.Key_Up);
                wait(260);
                compare(list.currentIndex, 2);
                compare(list.contentY, 112);
                console.info("PASS: keyboard viewport scroll is interpolated, synchronized and retargets rapid keys");
                if (directory) {
                    saved = false;
                    test.grabToImage(result => saved = result.saveToFile(directory + "/scrolled-selection.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                launcher.query = "Spotify";
                wait(250);
                if (directory) {
                    saved = false;
                    test.grabToImage(result => saved = result.saveToFile(directory + "/application-reference.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                console.info("PASS: fresh-open query reset and animated selection outline in both directions");
                launcher.query = "> echo never executed";
                launcher.focusSearch();
                keyClick(Qt.Key_Escape);
                compare(test.closes, 1);
                compare(launcher.query, "");
                compare(launcher.lastRequest, "");
                console.info("PASS: Escape from command input requests closure and clears input without execution");
                console.info("PASS: launcher terminal row, explicit Enter, no command execution, no command pinning and app-search restoration");
            }
        }
    }
}
