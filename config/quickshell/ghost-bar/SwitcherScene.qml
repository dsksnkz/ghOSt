import QtQuick
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
    property var fixtureWindows: ({})
    signal chosen(int workspace)
    signal closed

    readonly property real designScale: width / 1920
    readonly property real planeHeight: designScale > 0 ? height / designScale : 1080
    // Every desktop card has one size; stepping only slides them. Side cards
    // tuck behind the centre one and are dimmed. The shell Scale sizes them.
    readonly property real cardScale: Math.min(Theme.shellScale, 1.5)
    readonly property real centreScale: 658 / 1920 * cardScale
    readonly property real spacing: 520 * cardScale
    readonly property real magicScale: 293 / 1920 * cardScale
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
    signal magicChosen(string special)
    // Set when the chosen card fills the screen: it matches the real desktop, so hide at once.
    property bool handedOver: false
    property bool prepared: false
    readonly property bool shown: prepared && !handedOver && (open || reveal > .001 || leaving)
    // Captured once per open: a desktop change mid-animation must not rebuild previews.
    property var windowMap: ({})
    readonly property int selected: ring.length ? ring[Geometry.modulo(target, ring.length)] : 1

    function begin() {
        // Finish changing both models before any nested delegates are created.
        // Opening previously built the repeaters while their models were changing.
        prepared = false;
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
        const map = previewMode ? fixtureWindows : {};
        if (!previewMode)
            for (const workspace of Hyprland.workspaces.values)
                map[workspace.id > 0 ? workspace.id : workspace.name] = workspace.toplevels.values.map(window => {
                    const details = window.lastIpcObject ?? {};
                    return {
                        at: (details.at ?? [0, 0]).slice(),
                        size: (details.size ?? [0, 0]).slice(),
                        focusHistoryID: details.focusHistoryID ?? 0,
                        title: details.title ?? "",
                        appClass: details.class ?? "",
                        source: window.wayland ?? null
                    };
                });
        windowMap = map;
        positionMotion.enabled = false;
        target = Math.max(0, ring.indexOf(current));
        positionMotion.enabled = true;
        prepared = true;
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
    // The desktop's most recently used window names the centre card.
    readonly property var lead: windowsFor(selected).slice().sort((a, b) => a.focusHistoryID - b.focusHistoryID)[0] ?? null
    readonly property var leadEntry: lead?.appClass ? DesktopEntries.heuristicLookup(lead.appClass) : null

    // Leave the Wayland/key signal and its binding evaluation before building
    // nested models. Coalesce repeated shortcuts into one setup pass.
    function prepareOpen() {
        if (open)
            begin();
    }
    onOpenChanged: if (open)
        Qt.callLater(prepareOpen)
    Component.onCompleted: if (open)
        Qt.callLater(prepareOpen)

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
        opacity: scene.reveal * (1 - scene.expansion)
    }
    Rectangle {
        anchors.fill: parent
        visible: scene.shown
        color: "#000000"
        opacity: (scene.wallpaper ? .3 : .85) * scene.reveal * (1 - scene.expansion)
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
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
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
                readonly property bool chosen: scene.leaving && modelData === scene.selected
                objectName: "switcher-card-" + modelData
                width: 1920
                height: plane.height
                // Slides only. A chosen desktop fades the overview away rather than zooming.
                x: offset * scene.spacing
                y: -40 * scene.cardScale
                z: 10 - distance
                visible: distance < 1.6
                opacity: Math.min(1, (1.6 - distance) / .5) * scene.reveal * (scene.handedOver ? 1 : 1 - scene.expansion)
                scale: scene.centreScale
                // Side desktops turn their outer edge towards the viewer, as if on the inside of a curve.
                transform: Rotation {
                    origin.x: 960
                    origin.y: plane.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: Math.max(-1, Math.min(1, card.offset)) * -40
                    distanceToPlane: 2400
                }
                SwitcherPreview {
                    anchors.fill: parent
                    windows: scene.windowsFor(card.modelData)
                    monitor: scene.monitor
                    wallpaper: scene.wallpaper
                }
                // Side desktops sit back: dimmed, not shrunk.
                Rectangle {
                    anchors.fill: parent
                    radius: 26
                    color: "#000000"
                    opacity: .12 * Math.min(1, card.distance)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 26
                    color: "transparent"
                    border.width: 2 / card.scale
                    border.color: Qt.rgba(1, 1, 1, cardArea.containsMouse ? .5 : .18)
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
        // Title above the centre card: desktop number, app icon and window title.
        Rectangle {
            objectName: "switcher-title"
            readonly property real cardTop: plane.height / 2 - plane.height * scene.centreScale / 2 - 40 * scene.cardScale
            visible: scene.shown && scene.magicIndex < 0
            x: (1920 - width) / 2
            y: cardTop - height - 14
            width: titleRow.implicitWidth + 28
            height: 38
            radius: 10
            color: "#141414"
            opacity: .92 * scene.reveal * (1 - scene.expansion)
            Row {
                id: titleRow
                anchors.centerIn: parent
                spacing: 9
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: scene.selected
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Theme.demiWeight
                    color: "#8a8a8a"
                }
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    visible: status === Image.Ready
                    source: scene.leadEntry?.icon ? Quickshell.iconPath(scene.leadEntry.icon, true) : ""
                    sourceSize: Qt.size(20 * Screen.devicePixelRatio, 20 * Screen.devicePixelRatio)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 560)
                    elide: Text.ElideRight
                    text: !scene.lead ? "Empty desktop" : (scene.lead.title || scene.lead.appClass) + (scene.leadEntry?.name && scene.lead.title && scene.lead.title !== scene.leadEntry.name ? "  ·  " + scene.leadEntry.name : "")
                    font.family: Theme.font
                    font.pixelSize: 14
                    color: "#ffffff"
                }
            }
        }
        Text {
            objectName: "switcher-magic-heading"
            visible: scene.shown
            width: 1920
            y: plane.height - 305 * scene.cardScale
            horizontalAlignment: Text.AlignHCenter
            text: "Magic Workspaces"
            font.family: Theme.font
            font.pixelSize: 20 * scene.cardScale
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
                x: 960 + (modelData.x - 960 - 146.5) * scene.cardScale
                y: plane.height - 252 * scene.cardScale
                width: 293 * scene.cardScale
                height: width * plane.height / 1920
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
                    y: parent.height + 12 * scene.cardScale
                    horizontalAlignment: Text.AlignHCenter
                    text: magicCard.modelData.name
                    font.family: Theme.font
                    font.pixelSize: 20 * scene.cardScale
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
