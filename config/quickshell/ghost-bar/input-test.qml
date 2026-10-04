import QtQuick
import QtTest
import Quickshell

// Test entry only: run offscreen with both GHOST_*_FIXTURE flags set.
ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 900
        implicitHeight: 900
        TestCase {
            id: test
            name: "SidebarInput"
            when: true
            visible: true
            width: 900
            height: 900
            property int outsideEvents: 0
            property int escapeEvents: 0
            SidebarFigmaBody {
                id: sidebar
                width: 354
                height: 790
                previewMode: true
                opened: true
                screen: ({
                        name: "test"
                    })
                onCloseRequested: test.escapeEvents++
            }
            DismissArea {
                id: outside
                x: 500
                width: 200
                height: 200
                onDismissed: test.outsideEvents++
            }
            function test_escape_from_root() {
                wait(20);
                sidebar.forceActiveFocus();
                verify(sidebar.activeFocus);
                keyClick(Qt.Key_Escape);
                compare(escapeEvents, 1);
                console.info("PASS: sidebar Escape event");
            }
            function test_outside_pointer() {
                mouseClick(outside, 50, 50);
                compare(outsideEvents, 1);
                console.info("PASS: outside pointer event");
            }
            function cleanupTestCase() {
                Qt.quit();
            }
        }
    }
}
