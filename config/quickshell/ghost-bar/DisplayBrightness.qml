import QtQuick
import Quickshell
import Quickshell.Io

// One output's brightness through brightness.py: a laptop backlight or a
// monitor's own setting. Reads only while active.
Item {
    id: control
    property string screenName: ""
    property bool active: false
    // Null until the output has answered; an output without control stays null.
    property var percent: null
    property var pending: null
    visible: false

    function refresh() {
        if (active && screenName && !query.running && !write.running)
            query.running = true;
    }
    // A monitor takes a moment per command, so a drag only sends its latest value.
    function set(value) {
        percent = value;
        pending = value;
        flush();
    }
    function flush() {
        if (pending === null || write.running)
            return;
        write.command = ["python3", Quickshell.shellPath("brightness.py"), "set", screenName, String(pending)];
        pending = null;
        write.running = true;
    }
    onActiveChanged: refresh()
    onScreenNameChanged: refresh()
    Component.onCompleted: refresh()
    Process {
        id: query
        command: ["python3", Quickshell.shellPath("brightness.py"), "get", control.screenName]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(text.trim());
                // A monitor can be busy for a moment; keep the last known value.
                if (isFinite(value))
                    control.percent = value;
            }
        }
    }
    Process {
        id: write
        onRunningChanged: if (!running)
            Qt.callLater(control.flush)
    }
    // Brightness keys change a backlight behind the shell's back; a monitor
    // costs a slow bus round trip per read, so it is read once per activation.
    Timer {
        objectName: "brightness-refresh"
        interval: 3000
        repeat: true
        running: control.active && control.screenName.startsWith("eDP-")
        onTriggered: control.refresh()
    }
}
