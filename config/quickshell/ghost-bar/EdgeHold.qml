import QtQuick

// Nonvisual dwell/latch controller. Movement never restarts dwell or moves a latch.
QtObject {
    id: hold
    property bool hovered: false
    property real pointerY: 0
    readonly property int dwellMs: 200
    readonly property int exitGraceMs: 100
    property bool latched: false
    signal activated(real y)
    signal released

    onHoveredChanged: {
        if (hovered) {
            exitGrace.stop();
            if (!latched)
                dwell.restart();
        } else {
            dwell.stop();
            if (latched)
                exitGrace.restart();
        }
    }
    property Timer exitGrace: Timer {
        interval: hold.exitGraceMs
        onTriggered: if (!hold.hovered && hold.latched) {
            hold.latched = false;
            hold.released();
        }
    }
    property Timer dwell: Timer {
        interval: hold.dwellMs
        onTriggered: {
            if (hold.hovered && !hold.latched) {
                hold.latched = true;
                hold.activated(hold.pointerY);
            }
        }
    }
}
