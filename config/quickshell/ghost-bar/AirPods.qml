pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// One link to connected AirPods for the Bluetooth menu.
// airpods.py runs only while that menu is open and an Apple headset is connected.
Singleton {
    id: pods
    // A connected headset; airpods.py checks it is Apple's before talking to it.
    readonly property var device: Bluetooth.devices.values.find(d => d.connected && (d.icon || "").startsWith("audio-head")) ?? null
    readonly property bool wanted: Desk.panel === "bluetooth"
    property var state: ({})
    readonly property bool ready: !!state.apple && !!state.connected
    // The three modes every noise-cancelling model has; Off is left out, as on AirPods Pro 3.
    readonly property var modes: [
        {id: "transparency", name: "Transparency"}, {id: "adaptive", name: "Adaptive"},
        {id: "anc", name: "Noise cancelling"}
    ]

    function send(line) {
        if (ready)
            link.write(line + "\n");
    }
    // Show the new mode at once; the buds confirm it on the link.
    function setMode(mode) {
        if (!ready || state.mode === mode)
            return;
        send("mode " + mode);
        state = Object.assign({}, state, {mode: mode});
    }

    Process {
        id: link
        command: ["python3", Quickshell.shellPath("airpods.py"), pods.device?.address ?? ""]
        running: !!pods.device && pods.wanted
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    pods.state = JSON.parse(line);
                } catch (_) {}
            }
        }
        onRunningChanged: if (!running)
            pods.state = {}
    }
}
