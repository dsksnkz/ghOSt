import QtQuick
import Quickshell.Hyprland

// A special workspace is separate from activeWorkspace in Hyprland's IPC.
// Only the special workspace displayed on this output counts, not hidden ones.
QtObject {
    required property var monitor
    property var workspaces: Hyprland.workspaces.values
    readonly property int specialId: monitor?.lastIpcObject?.specialWorkspace?.id ?? 0
    readonly property var special: specialId !== 0
        ? workspaces.find(workspace => workspace.id === specialId) ?? null : null
    readonly property bool active: !!monitor &&
        ((monitor.activeWorkspace?.hasFullscreen ?? false) || (special?.hasFullscreen ?? false))
}
