import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import "WorkspaceWheel.js" as Geometry

// Workspace overview content. Previews are single-frame captures taken on open,
// so nothing is captured or animated while closed.
Item {
    id: scene
    property bool open: false
    property var monitor: null
    property bool previewMode: false
    property var fixtureRing: [1, 2, 3, 4, 5]
    property int fixtureCurrent: 1
    signal chosen(int workspace)
    signal closed

    readonly property real designScale: width / 1920
    readonly property real planeHeight: designScale > 0 ? height / designScale : 1080
    // Cards are laid out at full size and scaled, so they expand without resampling.
    readonly property real centreScale: 592 / 1920
    readonly property real sideScale: 423 / 1920
    readonly property real magicScale: 293 / 1920
    readonly property var magic: [
        {key: "special:ai", special: "ai", name: "AI", x: 766},
        {key: "special:music", special: "music", name: "Music", x: 1136}
    ]
    readonly property string wallpaper: previewMode ? "" : Settings.state.preferences?.wallpaper ? "file://" + Settings.state.preferences.wallpaper : ""
    property var ring: []
    property int target: 0
    property real position: target
    property real expansion: 0
    property bool leaving: false
    property real reveal: revealGate.open ? 1 : 0
    property int magicIndex: -1
    property real scrollRemainder: 0
    // Super is down when the shortcut opens this; letting go after moving confirms.
    property bool superHeld: true
    property int startTarget: 0
    signal magicChosen(string special)
    // Set when the chosen card fills the screen: it matches the real desktop, so hide at once.
    property bool handedOver: false
    readonly property bool shown: !handedOver && (open || reveal > .001 || leaving)
    // Captured once per open: a desktop change mid-animation must not rebuild previews.
    property var windowMap: ({})
    readonly property int selected: ring.length ? ring[Geometry.modulo(target, ring.length)] : 1

    function begin() {
        expandMotion.stop();
        leaving = false;
        handedOver = false;
        expansion = 0;
        magicIndex = -1;
        scrollRemainder = 0;
        const current = previewMode ? fixtureCurrent : Math.max(1, monitor?.activeWorkspace?.id ?? Desk.activeWorkspace);
        if (!previewMode)
            Hyprland.refreshToplevels();
        ring = previewMode ? fixtureRing : Geometry.ring(Hyprland.workspaces.values.map(w => ({
                id: w.id,
                windows: w.toplevels?.values.length ?? 0
            })), current);
        const map = {};
        if (!previewMode)
            for (const workspace of Hyprland.workspaces.values)
                map[workspace.id > 0 ? workspace.id : workspace.name] = workspace.toplevels.values.slice();
        windowMap = map;
        positionMotion.enabled = false;
        target = Math.max(0, ring.indexOf(current));
        positionMotion.enabled = true;
        superHeld = true;
        startTarget = target;
        input.forceActiveFocus();
    }
    function step(direction) {
        if (leaving || !ring.length)
            return;
        if (magicIndex >= 0)
            magicIndex = Geometry.modulo(magicIndex + direction, magic.length);
        else
            target += direction;
    }
    function scroll(delta) {
        magicIndex = -1;
        scrollRemainder += delta / 120;
        const notches = scrollRemainder > 0 ? Math.floor(scrollRemainder) : Math.ceil(scrollRemainder);
        scrollRemainder -= notches;
        if (notches)
            step(-notches);
    }
    function pickMagic(index) {
        if (leaving)
            return;
        magicChosen(magic[index].special);
        closed();
    }
    function offsetOf(index) {
        const count = ring.length;
        return Geometry.modulo(index - position + count / 2, count) - count / 2;
    }
    function confirm() {
        if (magicIndex >= 0) {
            pickMagic(magicIndex);
            return;
        }
        if (leaving || !ring.length)
            return;
        leaving = true;
        chosen(selected);
        expandMotion.restart();
    }
    function pick(index) {
        if (leaving)
            return;
        target += Math.round(offsetOf(index));
        confirm();
    }
    function windowsFor(workspace) {
        return windowMap[workspace] ?? [];
    }

    onOpenChanged: if (open)
        begin()
    Component.onCompleted: if (open)
        begin()

    RevealGate {
        id: revealGate
        target: scene.open
    }
    Behavior on reveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : scene.open ? 260 : 180
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
    }
    Behavior on position {
        id: positionMotion
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : 340
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
    }
    NumberAnimation {
        id: expandMotion
        target: scene
        property: "expansion"
        to: 1
        // Outlasts Hyprland's 260 ms workspace slide behind it.
        duration: Theme.reducedMotion ? 0 : 320
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        onFinished: {
            scene.leaving = false;
            scene.handedOver = true;
            scene.closed();
        }
    }

    // Decoded at shell start and shared by every card: opening never waits on it.
    Image {
        id: backdrop
        anchors.fill: parent
        source: scene.wallpaper
        sourceSize.width: 1920
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: scene.shown
        opacity: scene.reveal
        layer.enabled: visible
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: .6
            blurMax: 24
            brightness: -.18
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: scene.shown
        color: "#000000"
        opacity: (scene.wallpaper ? .35 : .85) * scene.reveal
    }
    MouseArea {
        anchors.fill: parent
        enabled: scene.shown
        onClicked: scene.closed()
        onWheel: event => scene.scroll(event.angleDelta.y || event.angleDelta.x)
    }
    Item {
        id: input
        focus: true
        function isSuper(key) {
            return key === Qt.Key_Meta || key === Qt.Key_Super_L || key === Qt.Key_Super_R;
        }
        Keys.onReleased: event => {
            if (!isSuper(event.key))
                return;
            if (scene.superHeld && (scene.target !== scene.startTarget || scene.magicIndex >= 0))
                scene.confirm();
            scene.superHeld = false;
            event.accepted = true;
        }
        Keys.onPressed: event => {
            if (isSuper(event.key))
                scene.superHeld = true;
            else if (event.key === Qt.Key_Escape)
                scene.closed();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                scene.confirm();
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                scene.step(1);
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
                scene.step(-1);
            else if (event.key === Qt.Key_Down)
                scene.magicIndex = Math.max(0, scene.magicIndex);
            else if (event.key === Qt.Key_Up)
                scene.magicIndex = -1;
            else
                return;
            event.accepted = true;
        }
    }

    Item {
        id: plane
        width: 1920
        height: scene.planeHeight
        scale: scene.designScale
        transformOrigin: Item.TopLeft
        visible: scene.shown
        Repeater {
            model: scene.shown ? scene.ring : []
            Item {
                id: card
                required property int modelData
                required property int index
                readonly property real offset: scene.offsetOf(index)
                readonly property real distance: Math.abs(offset)
                readonly property real nearness: Math.min(1, distance)
                // The chosen card zooms from wherever it is, with no jump mid-way.
                readonly property bool chosen: scene.leaving && modelData === scene.selected
                readonly property real restScale: scene.centreScale + (scene.sideScale - scene.centreScale) * nearness
                objectName: "switcher-card-" + modelData
                width: 1920
                height: plane.height
                x: (offset < 0 ? -654 : 654) * Math.min(1.5, distance)
                z: chosen ? 10 : 2 - distance
                visible: distance < 1.5
                opacity: (chosen ? 1 : Math.min(1, (1.5 - distance) / .5)) * scene.reveal * (chosen || scene.handedOver ? 1 : 1 - scene.expansion)
                scale: (chosen ? restScale + (1 - restScale) * scene.expansion : restScale) * (.97 + .03 * scene.reveal)
                Text {
                    objectName: "switcher-number-" + card.modelData
                    width: parent.width
                    y: -150
                    horizontalAlignment: Text.AlignHCenter
                    text: card.modelData
                    font.family: Theme.font
                    font.pixelSize: 65
                    color: "#ffffff"
                    opacity: 1 - scene.expansion
                }
                SwitcherPreview {
                    anchors.fill: parent
                    windows: scene.windowsFor(card.modelData)
                    monitor: scene.monitor
                    wallpaper: scene.wallpaper
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 26
                    color: "transparent"
                    border.width: 1 / card.scale
                    border.color: Qt.rgba(1, 1, 1, (cardArea.containsMouse ? .6 : .32) * (1 - scene.expansion))
                }
                MouseArea {
                    id: cardArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: scene.pick(card.index)
                    onWheel: event => scene.scroll(event.angleDelta.y || event.angleDelta.x)
                }
            }
        }
        Text {
            objectName: "switcher-magic-heading"
            visible: scene.shown
            width: 1920
            y: plane.height - 305
            horizontalAlignment: Text.AlignHCenter
            text: "Magic Workspaces"
            font.family: Theme.font
            font.pixelSize: 20
            color: "#ffffff"
            opacity: scene.reveal * (1 - scene.expansion)
        }
        Repeater {
            model: scene.shown ? scene.magic : []
            Item {
                id: magicCard
                required property var modelData
                required property int index
                readonly property bool selected: scene.magicIndex === index
                objectName: "switcher-magic-" + modelData.special
                x: modelData.x - 146.5
                y: plane.height - 252
                width: 293
                height: 293 * plane.height / 1920
                opacity: scene.reveal * (1 - scene.expansion)
                Item {
                    width: 1920
                    height: plane.height
                    scale: scene.magicScale
                    transformOrigin: Item.TopLeft
                    SwitcherPreview {
                        anchors.fill: parent
                        resolution: .5
                        windows: scene.windowsFor(magicCard.modelData.key)
                        monitor: scene.monitor
                        wallpaper: scene.wallpaper
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 26 * scene.magicScale
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, magicCard.selected ? 1 : magicArea.containsMouse ? .6 : .32)
                }
                Text {
                    width: parent.width
                    y: parent.height + 12
                    horizontalAlignment: Text.AlignHCenter
                    text: magicCard.modelData.name
                    font.family: Theme.font
                    font.pixelSize: 20
                    color: "#ffffff"
                }
                MouseArea {
                    id: magicArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: scene.pickMagic(magicCard.index)
                }
            }
        }
    }
}
