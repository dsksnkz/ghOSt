import QtQuick
import QtTest
import Quickshell

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 600
        implicitHeight: 412
        color: "#191919"
        TestCase {
            id: test
            visible: true
            anchors.fill: parent
            property bool saved: false
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
                launcher.move(1);
                wait(70);
                if (!Theme.reducedMotion)
                    verify(outline.y > 0 && outline.y < 90);
                wait(240);
                compare(outline.y, 90);
                launcher.move(-1);
                wait(250);
                compare(outline.y, 0);
                launcher.query = "Spotify";
                wait(250);
                if (directory) {
                    saved = false;
                    test.grabToImage(result => saved = result.saveToFile(directory + "/application-reference.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                console.info("PASS: fresh-open query reset and animated selection outline in both directions");
                console.info("PASS: launcher terminal row, explicit Enter, no command execution, no command pinning and app-search restoration");
            }
        }
    }
}
