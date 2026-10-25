import QtQuick
import Quickshell

// Read-only frame pacing diagnostics for `quickshell ipc call bar frameStart/frameStop`.
// Records animation-driver tick intervals only while armed; idle otherwise.
Scope {
    id: probe
    property bool recording: false
    property var intervals: []
    function start() {
        intervals = [];
        recording = true;
    }
    function stop() {
        recording = false;
        const d = intervals.slice(1).sort((a, b) => a - b);
        if (!d.length)
            return JSON.stringify({ frames: 0 });
        const mean = d.reduce((a, b) => a + b, 0) / d.length;
        const pick = q => d[Math.min(d.length - 1, Math.floor(d.length * q))];
        return JSON.stringify({
            frames: d.length + 1,
            fps: Math.round(1000 / mean * 10) / 10,
            p50: Math.round(pick(.5) * 100) / 100,
            p95: Math.round(pick(.95) * 100) / 100,
            max: Math.round(d[d.length - 1] * 100) / 100,
            over8ms: d.filter(v => v > 8).length,
            over17ms: d.filter(v => v > 16.7).length,
            sequence: intervals.slice(1, 90).map(v => Math.round(v * 10) / 10)
        });
    }
    FrameAnimation {
        running: probe.recording
        onTriggered: probe.intervals.push(frameTime * 1000)
    }
}
