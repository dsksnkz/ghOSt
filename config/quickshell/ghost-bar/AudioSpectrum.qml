import QtQuick
import Quickshell
import Quickshell.Io

// One bounded Cava frame per update; no fake amplitude or media metadata.
QtObject {
    id: spectrum
    property bool active: false
    readonly property int barCount: 15
    property var levels: Array(barCount).fill(0)
    readonly property bool fixture: Quickshell.env("GHOST_CALENDAR_FIXTURE") === "1"
        || Quickshell.env("GHOST_SETTINGS_FIXTURE") === "1"
    readonly property bool running: capture.running

    function acceptFrame(line) {
        const values = line.trim().replace(/;$/, "").split(";");
        if (values.length !== barCount)
            return false;
        const next = [];
        for (const value of values) {
            if (!/^\d+$/.test(value))
                return false;
            const amplitude = Number(value);
            if (amplitude > 1000)
                return false;
            next.push(amplitude / 1000);
        }
        levels = next;
        return true;
    }

    property Process capture: Process {
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        running: spectrum.active && !spectrum.fixture
        stdout: SplitParser {
            onRead: line => spectrum.acceptFrame(line)
        }
        onExited: spectrum.levels = Array(spectrum.barCount).fill(0)
    }
}
