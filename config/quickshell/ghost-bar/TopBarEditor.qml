import QtQuick
import "RailLayout.js" as Layout

Column {
    id: editor
    spacing: 14
    property var savedLayout: null
    property var draft: Layout.defaults()
    property bool dirty: false
    property bool busy: false
    property string selectedId: ""
    property string soundGroup: "settings"
    signal applyRequested(string value)

    function resetDraft() {
        draft = (savedLayout || Layout.defaults()).map(entry => ({id: entry.id, zone: entry.zone}));
        dirty = false;
    }
    function place(id, zone, target, after) {
        draft = Layout.place(draft, id, zone, target, after);
        selectedId = id;
        dirty = true;
    }
    function move(id, step) {
        draft = Layout.move(draft, draft.findIndex(entry => entry.id === id), step);
        dirty = true;
    }
    function queueDrop(drop, zone, target, after) {
        const id = drop.source.elementId;
        // Finish the pointer sequence before rebuilding the delegates.
        Qt.callLater(() => editor.place(id, zone, target, after));
        drop.acceptProposedAction();
    }
    onSavedLayoutChanged: {
        if (JSON.stringify(savedLayout || Layout.defaults()) === JSON.stringify(draft))
            dirty = false;
        if (!dirty)
            resetDraft();
    }
    Component.onCompleted: resetDraft()

    Label {
        text: "Top bar"
        font.pixelSize: 16
        font.weight: Font.DemiBold
        color: "#f1f1f1"
    }
    Label {
        width: parent.width
        text: "Drag elements to move, reorder or hide them."
        color: "#b8b8b8"
        font.pixelSize: 11
    }
    G2Surface {
        width: parent.width
        height: 56
        radius: 8
        color: "#191919"
        border.width: 1
        border.color: "#383838"
        Rail {
            id: previewRail
            objectName: "rail-layout-preview"
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: implicitHeight * width / 1920
            previewMode: true
            layoutOverride: editor.draft
            active: false
            enabled: false
        }
    }

    component Element: Item {
        id: slot
        required property var entry
        width: entry.id === "clock" || entry.id === "music" ? 68 : 36
        height: 52
        readonly property string name: Layout.items.find(item => item.id === entry.id).name
        G2Surface {
            id: face
            objectName: "rail-drag-" + slot.entry.id
            property string elementId: slot.entry.id
            width: slot.width
            height: slot.height
            radius: 8
            color: drag.drag.active ? "#454545" : editor.selectedId === elementId ? "#343434" : "#252525"
            border.width: 1
            border.color: drag.drag.active || activeFocus ? "#eeeeee" : target.containsDrag ? "#b8b8b8" : "#414141"
            activeFocusOnTab: true
            focus: editor.selectedId === elementId
            onActiveFocusChanged: if (activeFocus) editor.selectedId = elementId
            Accessible.role: Accessible.ListItem
            Accessible.name: slot.name + ", " + slot.entry.zone
            Drag.keys: ["ghost-rail-element"]
            Drag.source: face
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            Drag.supportedActions: Qt.MoveAction
            Keys.onLeftPressed: editor.move(elementId, -1)
            Keys.onRightPressed: editor.move(elementId, 1)
            Keys.onDeletePressed: editor.place(elementId, "hidden", "", false)
            Keys.onPressed: event => {
                const zone = {"1": "left", "2": "center", "3": "right", "0": "hidden"}[event.text];
                if (zone) {
                    editor.place(elementId, zone, "", false);
                    event.accepted = true;
                }
            }
            SvgIcon {
                anchors.centerIn: parent
                width: 19
                height: 19
                visible: !["clock", "music", "workspaces"].includes(face.elementId)
                name: ({menu: "menu", workspaces: "app", volume: "volume", network: "wifi", bluetooth: "bluetooth", battery: "battery", power: "power"})[face.elementId] || "app"
            }
            Label {
                anchors.centerIn: parent
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                visible: ["clock", "music", "workspaces"].includes(face.elementId)
                text: face.elementId === "clock" ? Qt.formatDateTime(previewRail.displayTime, "HH:mm") : face.elementId === "workspaces" ? "01" : "Music  ▷"
                color: "#f1f1f1"
                font.pixelSize: 11
            }
            MouseArea {
                id: drag
                anchors.fill: parent
                preventStealing: true
                drag.target: face
                drag.threshold: 8
                cursorShape: drag.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                function restore() {
                    face.Drag.active = false;
                    face.parent = slot;
                    face.x = 0;
                    face.y = 0;
                }
                onPressed: {
                    editor.selectedId = face.elementId;
                    face.forceActiveFocus();
                }
                drag.onActiveChanged: if (drag.drag.active) {
                    const position = face.mapToItem(dragLayer, 0, 0);
                    face.parent = dragLayer;
                    face.x = position.x;
                    face.y = position.y;
                    face.Drag.active = true;
                }
                onReleased: {
                    if (face.Drag.active)
                        face.Drag.drop();
                    restore();
                }
                onCanceled: restore()
            }
        }
        DropArea {
            id: target
            anchors.fill: parent
            keys: ["ghost-rail-element"]
            onDropped: drop => editor.queueDrop(drop, slot.entry.zone, slot.entry.id, drop.x > width / 2)
        }
    }

    component Zone: G2Surface {
        id: zone
        required property string zoneId
        required property string title
        readonly property real desiredHeight: tiles.height + 44
        radius: 8
        color: area.containsDrag ? "#292929" : "#171717"
        border.width: 1
        border.color: area.containsDrag ? "#cccccc" : "#3a3a3a"
        DropArea {
            id: area
            objectName: "rail-drop-" + zone.zoneId
            anchors.fill: parent
            keys: ["ghost-rail-element"]
            onDropped: drop => editor.queueDrop(drop, zone.zoneId, "", false)
        }
        Label {
            x: 10
            y: 9
            text: zone.title
            color: "#b8b8b8"
            font.pixelSize: 10
        }
        Flow {
            id: tiles
            x: 10
            y: 32
            width: parent.width - 20
            spacing: 6
            Repeater {
                model: editor.draft.filter(entry => entry.zone === zone.zoneId)
                Element { required property var modelData; entry: modelData }
            }
        }
    }
    Row {
        width: parent.width
        spacing: 8
        height: Math.max(108, left.desiredHeight, center.desiredHeight, right.desiredHeight)
        Zone { id: left; width: (parent.width - 16) / 3; height: parent.height; zoneId: "left"; title: "Left" }
        Zone { id: center; width: (parent.width - 16) / 3; height: parent.height; zoneId: "center"; title: "Center" }
        Zone { id: right; width: (parent.width - 16) / 3; height: parent.height; zoneId: "right"; title: "Right" }
    }
    Zone {
        width: parent.width
        height: Math.max(92, desiredHeight)
        zoneId: "hidden"
        title: "Hidden · drag here to remove an element"
    }
    Label {
        width: parent.width
        text: editor.selectedId ? Layout.items.find(item => item.id === editor.selectedId).name : "Select an element to see its name"
        color: "#f1f1f1"
        font.pixelSize: 12
    }
    Label {
        width: parent.width
        text: "Keyboard: ← / → reorder · 1 / 2 / 3 position · Delete hide"
        color: "#b8b8b8"
        font.pixelSize: 10
    }
    Row {
        spacing: 12
        Key {
            objectName: "rail-layout-apply"
            width: 120
            height: 38
            text: "Apply"
            selected: true
            enabled: editor.dirty && !editor.busy
            onClicked: editor.applyRequested(JSON.stringify(editor.draft))
        }
        Key {
            width: 160
            height: 38
            text: "Restore default"
            enabled: !editor.busy
            onClicked: {
                editor.draft = Layout.defaults();
                editor.dirty = false;
                editor.applyRequested("default");
            }
        }
    }
    Item {
        id: dragLayer
        z: 100
        width: editor.width
        height: 0
    }
}
