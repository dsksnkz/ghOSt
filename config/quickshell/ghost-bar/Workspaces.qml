import QtQuick
import Quickshell.Hyprland

Item {
    id: root
    property var monitor
    readonly property int current: monitor?.activeWorkspace?.id ?? Desk.activeWorkspace
    readonly property var ids: {
        let list = [1, 2, 3, 4, 5];
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 5 && !list.includes(ws.id)) list.push(ws.id);
        if (current > 0 && !list.includes(current)) list.push(current);
        return list.sort((a,b) => a-b);
    }
    width: ids.length * 34
    height: 32
    Rectangle {
        x: Math.max(0, root.ids.indexOf(root.current)) * 34 + 2
        y: 3; width: 30; height: 25; radius: 4
        color: Theme.cream
        Behavior on x { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        x: Math.max(0, root.ids.indexOf(root.current)) * 34 + 14
        y: 31; width: 6; height: 2; color: Theme.orange
        Behavior on x { NumberAnimation { duration: 230; easing.type: Easing.OutQuint } }
    }
    Row {
        Repeater {
            model: root.ids
            Key {
                required property int modelData
                readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === modelData && w.toplevels.values.length > 0)
                width: 34; height: 30; padding: 0
                text: String(modelData).padStart(2, "0")
                hint: "Workspace " + modelData
                ink: root.current === modelData ? Theme.base : occupied ? Theme.text : Theme.faint
                color: "transparent"
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData + " })")
                onScrolled: delta => Hyprland.dispatch("hl.dsp.focus({ workspace = '" + (delta > 0 ? "e-1" : "e+1") + "' })")
            }
        }
    }
}
