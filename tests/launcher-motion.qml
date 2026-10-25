import QtQuick
import QtTest
import Quickshell
import "PanelMotion.js" as Motion

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 560
        implicitHeight: 430
        color: "#101010"
        TestCase {
            id: test
            anchors.fill: parent
            visible: true
            property bool saved: false
            QtObject {
                id: popup
                property string page: "launcher"
                property real reveal: 0
                property bool opened: true
            }
            PanelContent {
                id: panel
                popup: popup
                previewMode: true
                width: 560
                height: implicitHeight
                // Window top plus the lead under the rail; content slides inside it.
                y: Motion.topMargin(popup.page, popup.reveal, implicitHeight) + Motion.windowLead(popup.page)
            }
            function test_motion() {
                try { checkMotion(); }
                catch (error) { console.error("FAIL! motion: " + error + " " + error.stack); throw error; }
            }
            function checkMotion() {
                compare(Motion.duration("launcher", false, 220), 150);
                compare(Motion.duration("launcher", true, 220), 0);
                compare(Motion.duration("audio", false, 220), 220);
                wait(100);
                panel.launcherAction("query", "> echo ghOSt");
                const height = panel.height;
                compare(height, 328);
                let previous = -height - 1;
                for (const amount of [0, .25, .6, 1]) {
                    popup.reveal = amount;
                    wait(30);
                    compare(panel.transform[1].xScale, 1);
                    compare(panel.transform[1].yScale, 1);
                    compare(panel.opacity, 1);
                    fuzzyCompare(panel.transform[0].y, Motion.slideOffset("launcher", amount, height), .001);
                    const start = panel.mapToItem(test, 0, 0);
                    const end = panel.mapToItem(test, panel.width, panel.height);
                    compare(end.x - start.x, 560);
                    compare(end.y - start.y, height);
                    verify(start.y > previous);
                    previous = start.y;
                    if (amount === 0) compare(start.y + height, 0);
                    if (amount === 1) compare(start.y, 68);
                    const directory = Quickshell.env("GHOST_MOTION_CAPTURE_DIR");
                    if (directory && amount > 0) {
                        saved = false;
                        test.grabToImage(result => saved = result.saveToFile(directory + "/slide-" + amount + ".png"));
                        tryCompare(test, "saved", true, 2000);
                    }
                }
                popup.page = "none";
                popup.reveal = .5;
                compare(panel.transform[1].xScale, .59);
                compare(panel.transform[1].yScale, .55);
                compare(panel.opacity, .5);
                compare(Motion.topMargin("calendar", .5, height), 82);
                compare(Motion.topMargin("audio", .5, height), 68);
                // Media: the window stays still; only content slides, by fractional offsets.
                for (const amount of [0, .37, 1])
                    compare(Motion.topMargin("media", amount, 262), 0);
                compare(Motion.windowLead("media"), 68);
                compare(Motion.windowLead("audio"), 0);
                compare(Motion.slideOffset("media", 0, 262), -330);
                compare(Motion.slideOffset("media", 1, 262), 0);
                fuzzyCompare(Motion.slideOffset("media", .37, 262), -207.9, .001);
                compare(Motion.slideOffset("audio", .37, 262), 0);
                popup.page = "media";
                popup.reveal = .37;
                wait(30);
                compare(panel.transform[1].xScale, 1);
                compare(panel.transform[1].yScale, 1);
                compare(panel.opacity, 1);
                compare(panel.transform[0].y, Motion.slideOffset("media", .37, panel.height));
                popup.reveal = 1;
                compare(panel.transform[0].y, 0);
                for (const amount of [0, .5, 1])
                    compare(Motion.topMargin("launcher", amount, height), 0);
                compare(Motion.windowLead("launcher"), 68);
                console.info("PASS: launcher slides from above screen to y68 at constant 560x328, no fade or scale; other popup motion retained");
            }
        }
    }
}
