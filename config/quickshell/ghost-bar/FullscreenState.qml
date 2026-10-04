import QtQuick

// Per-output, event-driven state; an unavailable monitor keeps the rail usable.
QtObject {
    required property var monitor
    readonly property bool active: monitor?.activeWorkspace?.hasFullscreen ?? false
}
