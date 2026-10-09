import QtQuick
import Quickshell.Hyprland
import Quickshell
import "WorkspaceWheel.js" as Geometry

Item {
    id: wheel
    property var monitor
    property int fixtureWorkspace: -1
    property var fixtureWindows: []
    readonly property bool previewMode: fixtureWorkspace > 0
    readonly property int current: previewMode ? fixtureWorkspace : Math.max(1, monitor?.activeWorkspace?.id ?? Desk.activeWorkspace)
    readonly property var population: previewMode ? fixtureWindows : Hyprland.workspaces.values.map(w => ({
                id: w.id,
                windows: w.toplevels?.values.length ?? 0
            }))
    readonly property var workspaceRing: Geometry.ring(population, current)
    readonly property string ringSignature: workspaceRing.join(",")
    property real position: 0
    property int targetIndex: 0
    property int inputDirection: 0
    property real scrollRemainder: 0
    property bool ready: false
    function reset() {
        rotation.stop();
        targetIndex = workspaceRing.indexOf(current);
        position = targetIndex;
    }
    function move() {
        if (!ready)
            return;
        const next = workspaceRing.indexOf(current);
        const delta = Geometry.distance(Geometry.modulo(targetIndex, workspaceRing.length), next, workspaceRing.length, inputDirection);
        inputDirection = 0;
        targetIndex += delta;
        rotation.stop();
        if (Theme.reducedMotion)
            position = targetIndex;
        else {
            rotation.to = targetIndex;
            rotation.restart();
        }
    }
    function select(workspace) {
        if (previewMode)
            fixtureWorkspace = workspace;
        else
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspace + " })");
    }
    function scroll(delta) {
        scrollRemainder += delta / 120;
        const notches = scrollRemainder > 0 ? Math.floor(scrollRemainder) : Math.ceil(scrollRemainder);
        if (!notches)
            return;
        scrollRemainder -= notches;
        inputDirection = notches > 0 ? -1 : 1;
        if (previewMode) {
            const allowed = Geometry.ring(population, 1);
            let index = allowed.indexOf(current);
            if (index < 0) {
                const insertion = allowed.findIndex(id => id > current);
                index = (insertion < 0 ? allowed.length : insertion) - (inputDirection > 0 ? 1 : 0);
            }
            select(allowed[Geometry.modulo(index + inputDirection * Math.abs(notches), allowed.length)]);
        } else
            Quickshell.execDetached(["python3", Quickshell.shellPath("workspace_scroll.py"), String(inputDirection), String(Math.abs(notches))]);
    }
    width: 99
    height: 46
    clip: true
    onCurrentChanged: move()
    onRingSignatureChanged: if (ready)
        reset()
    Component.onCompleted: {
        reset();
        ready = true;
    }
    Connections {
        target: Theme
        function onReducedMotionChanged() {
            if (Theme.reducedMotion) {
                rotation.stop();
                wheel.position = wheel.targetIndex;
            }
        }
    }
    NumberAnimation {
        id: rotation
        target: wheel
        property: "position"
        duration: 320
        easing.type: Easing.OutCubic
        onFinished: {
            wheel.position = Geometry.modulo(wheel.targetIndex, wheel.workspaceRing.length);
            wheel.targetIndex = wheel.position;
        }
    }
    Repeater {
        id: digits
        model: [-2, -1, 0, 1, 2]
        Item {
            required property int modelData
            readonly property int slot: Math.floor(wheel.position) + modelData
            readonly property int workspace: wheel.workspaceRing[Geometry.modulo(slot, wheel.workspaceRing.length)] ?? 1
            readonly property real offset: slot - wheel.position
            readonly property var projection: Geometry.project(offset)
            x: projection.x
            y: projection.y
            width: 23
            height: 18
            opacity: projection.opacity
            z: projection.depth
            visible: opacity > 0
            transform: [
                Scale {
                    origin.x: 11.5
                    origin.y: 0
                    xScale: projection.scale
                    yScale: projection.scale
                },
                Rotation {
                    origin.x: 11.5
                    origin.y: 9
                    axis.y: 1
                    axis.z: 0
                    angle: projection.rotation
                }
            ]
            Label {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                text: String(parent.workspace).padStart(2, "0")
                font.family: Theme.font
                font.pixelSize: 15
                font.weight: Math.abs(parent.offset) < .5 ? Font.Bold : Font.Medium
                color: Qt.rgba(parent.projection.ink / 255, parent.projection.ink / 255, parent.projection.ink / 255, 1)
            }
        }
    }
    // Fixed hit targets stay responsive while the projected labels rotate.
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.NoButton
        onWheel: event => wheel.scroll(event.angleDelta.y || event.angleDelta.x)
    }
    Repeater {
        model: [-1, 0, 1]
        Key {
            required property int modelData
            readonly property int workspace: wheel.workspaceRing[Geometry.modulo(Math.round(wheel.position) + modelData, wheel.workspaceRing.length)] ?? 1
            x: modelData < 0 ? 0 : modelData === 0 ? 36 : 76
            width: 23
            height: 46
            color: "transparent"
            hint: "Workspace " + workspace
            onClicked: {
                Desk.close();
                wheel.select(workspace);
            }
            wheelEnabled: true
            onScrolled: delta => wheel.scroll(delta)
        }
    }
    Icon {
        id: indicator
        x: 36 + (23 - width) / 2
        y: 29
        width: 14
        height: 6
        z: 5
        name: "workspace-indicator"
        fillMode: Image.Stretch
        ink: "#aeaeae"
    }
    function status() {
        const rendered = [];
        for (let i = 0; i < digits.count; i++) {
            const item = digits.itemAt(i);
            if (item.visible)
                rendered.push({
                    workspace: item.workspace,
                    offset: item.offset,
                    x: item.x,
                    y: item.y,
                    scale: item.projection.scale,
                    rotation: item.projection.rotation,
                    opacity: item.opacity
                });
        }
        return {
            current,
            ring: workspaceRing,
            position,
            target: targetIndex,
            moving: rotation.running,
            remainder: scrollRemainder,
            triangle: {
                x: indicator.x,
                y: indicator.y,
                width: indicator.width
            },
            rendered
        };
    }
    function fixturePose(phase) {
        if (previewMode) {
            rotation.stop();
            position = phase;
        }
    }
}
