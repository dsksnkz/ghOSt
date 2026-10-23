import QtQuick
import QtTest
import Quickshell

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 1920
        implicitHeight: 52
        TestCase {
            id: test
            visible: true
            anchors.fill: parent
            property bool saved: false
            Rail { id: rail; width: 1920; screenName: "test"; previewMode: true }
            function test_clock() {
                wait(150);
                const clock = findChild(rail, "rail-clock-control");
                const label = findChild(rail, "rail-clock-text");
                compare(label.text, "09:21");
                compare(clock.children.filter(child => child.text !== undefined && child.text.length > 0).length, 1);
                const directory = Quickshell.env("GHOST_RAIL_CAPTURE_DIR");
                if (directory) {
                    rail.grabToImage(result => saved = result.saveToFile(directory + "/rail.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                for (const width of [1920, 1366]) {
                    rail.width = width;
                    wait(30);
                    const state = rail.spacingStatus();
                    verify(Math.abs(state.clockCenterX - width / 2) < 0.01);
                    Desk.close();
                    mouseClick(clock, clock.width / 2, clock.height / 2);
                    compare(Desk.panel, "calendar");
                    Desk.close();
                }
                console.info("PASS: center contains only clock, exact centering at two widths and calendar click retained");
            }
        }
    }
}
