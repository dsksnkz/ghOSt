import QtQuick
import QtTest
import Quickshell

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 392
        implicitHeight: 460
        color: "#151515"
        TestCase {
            id: test
            visible: true
            anchors.fill: parent
            property bool saved: false
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
                    launcher.grabToImage(result => saved = result.saveToFile(directory + "/terminal-mode.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                launcher.query = "kitty";
                compare(launcher.commandMode, false);
                verify(launcher.results.every(entry => !entry.terminalCommand));
                console.info("PASS: launcher terminal row, explicit Enter, no command execution, no command pinning and app-search restoration");
            }
        }
    }
}
