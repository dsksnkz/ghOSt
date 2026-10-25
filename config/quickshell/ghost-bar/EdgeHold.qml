import QtQuick

// Nonvisual dwell/latch controller. Movement never restarts dwell or moves a latch.
QtObject {
    id: hold
    property bool hovered: false
    property real pointerY: 0
    readonly property int dwellMs: 200
    property bool latched: false
    signal activated(real y)
    signal released

    onHoveredChanged: {
        if (hovered) {
            dwell.restart();
        } else {
            dwell.stop();
            if (latched) {
                latched = false;
                released();
            }
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
