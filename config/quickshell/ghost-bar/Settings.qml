pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: settings
    property bool active: false
    property string page: "general"
    // Battery, disk space and external brightness changes need frequent reads.
    // Other pages use live service bindings or change only on explicit actions.
    readonly property int refreshInterval: ["battery", "storage", "brightness"].includes(page) ? 5000 : 60000
    property int queryCount: 0
    readonly property bool fixture: Quickshell.env("GHOST_SETTINGS_FIXTURE") === "1"
    property var state: ({
            preferences: {
                reducedMotion: false,
                usageTracking: false,
                widgets: {}
            }
        })
    property string error: ""
    readonly property bool busy: change.running
    function widget(name) {
        return state.preferences?.widgets?.[name] !== false;
    }
    function refresh() {
        if (!fixture && !query.running && !change.running) {
            queryCount++;
            query.running = true;
        }
    }
    function pollingStatus() {
        return {
            active: active,
            page: page,
            interval: refreshInterval,
            timerRunning: refreshTimer.running,
            queries: queryCount,
            queryRunning: query.running
        };
    }
    function receive(text) {
        try {
            const result = JSON.parse(text);
            if (!result.ok) {
                error = result.error;
                return;
            }
            state = result.state;
            error = "";
            Theme.reducedMotion = !!state.preferences.reducedMotion;
        } catch (_) {
            error = "Could not read Settings";
        }
    }
    function apply(name, value) {
        if (fixture) {
            error = "Preview — system actions disabled";
            return;
        }
        if (change.running)
            return;
        change.command = ["python3", Quickshell.shellPath("settings_backend.py"), "action", name, String(value)];
        change.running = true;
    }
    function preference(name, value) {
        apply("preference", name + "=" + String(value));
    }
    onActiveChanged: if (active)
        refresh()
    onPageChanged: if (active)
        refresh()
    Component.onCompleted: refresh()
    Process {
        id: query
        command: ["python3", Quickshell.shellPath("settings_backend.py"), "status"]
        stdout: StdioCollector {
            onStreamFinished: settings.receive(text)
        }
    }
    Process {
        id: change
        stdout: StdioCollector {
            onStreamFinished: settings.receive(text)
        }
    }
    Process {
        id: sample
        command: ["python3", Quickshell.shellPath("settings_backend.py"), "sample"]
        stdout: StdioCollector {
            onStreamFinished: settings.receive(text)
        }
    }
    Timer {
        id: refreshTimer
        interval: settings.refreshInterval
        repeat: true
        running: settings.active && !settings.fixture
        onTriggered: settings.refresh()
    }
    Timer {
        interval: 60000
        repeat: true
        running: !!settings.state.preferences?.usageTracking && !settings.fixture
        onTriggered: if (!sample.running)
            sample.running = true
    }
}
