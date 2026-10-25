import QtQuick
import Quickshell

// Starts a surface's reveal only after the frames that map the window and
// build its content have passed. Those first frames can take 20–70 ms; an
// animation already running through them skips a visible part of its travel.
// The heavy frames arrive a few ticks after the trigger, so `open` follows
// `target` only after `minimumFrames` ticks and then two consecutive short
// frames, or after `maximumWait` ms; the motion runs at the display rate.
Scope {
    id: gate
    property bool target: false
    property bool open: false
    property real shortFrame: 9
    property int minimumFrames: 6
    property real maximumWait: 120
    property int calm: 0
    property int frames: 0
    property real waited: 0
    onTargetChanged: {
        calm = 0;
        frames = 0;
        waited = 0;
        if (Theme.reducedMotion) {
            watcher.running = false;
            open = target;
        } else {
            watcher.running = true;
        }
    }
    Component.onCompleted: open = target
    FrameAnimation {
        id: watcher
        running: false
        onTriggered: {
            const ms = frameTime * 1000;
            gate.waited += ms;
            gate.frames++;
            gate.calm = ms < gate.shortFrame ? gate.calm + 1 : 0;
            if ((gate.frames >= gate.minimumFrames && gate.calm >= 2) || gate.waited >= gate.maximumWait) {
                running = false;
                gate.open = gate.target;
            }
        }
    }
}
