import QtQuick
import QtTest
import Quickshell

ShellRoot {
    EdgeHold {
        id: edge
        onActivated: y => OsdState.holdEdge("fixture", "left", y)
        onReleased: OsdState.releaseEdge("fixture", "left")
    }
    SignalSpy { id: activations; target: edge; signalName: "activated" }
    TestCase {
        name: "EdgeHold"
        function test_dwell_latch_release() {
            compare(edge.dwellMs, 500);
            edge.pointerY = 200;
            edge.hovered = true;
            wait(250);
            compare(edge.latched, false);
            compare(OsdState.opened, false);
            edge.hovered = false;
            wait(300);
            compare(activations.count, 0);

            edge.hovered = true;
            wait(300);
            edge.pointerY = 450;
            wait(100);
            compare(edge.latched, false);
            tryCompare(edge, "latched", true, 400);
            compare(activations.count, 1);
            compare(OsdState.pointerY, 450);
            verify(OsdState.edgeHeld && OsdState.opened);
            edge.pointerY = 650;
            wait(50);
            compare(OsdState.pointerY, 450);
            OsdState.holdEdge("fixture", "left", 800);
            compare(OsdState.pointerY, 450);
            Desk.setVolume(.32);
            wait(2300);
            verify(OsdState.edgeHeld && OsdState.opened);
            compare(OsdState.pointerY, 450);
            compare(activations.count, 1);
            OsdState.releaseEdge("fixture", "right");
            verify(OsdState.opened);
            edge.hovered = false;
            compare(OsdState.edgeHeld, false);
            compare(OsdState.opened, false);

            edge.pointerY = 700;
            edge.hovered = true;
            tryCompare(edge, "latched", true, 700);
            compare(OsdState.pointerY, 700);
            edge.hovered = false;
            OsdState.show("volume", "fixture");
            verify(!OsdState.edgeHeld && OsdState.opened);
            compare(OsdState.pointerY, -1);
            tryCompare(OsdState, "opened", false, 2600);
            console.log("PASS: 500ms dwell/cancel, fixed origin, held visibility, audio updates, release/reentry and normal expiry");
        }
    }
}
