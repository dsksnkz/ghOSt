import QtQuick
import Quickshell
import Quickshell.Wayland

// Power menu from the top bar's power button. The screen behind blurs (a
// Hyprland layer rule on "ghost-power"), a large circle grows out of the button,
// then the actions slide out of it along an arc, one after another.
// Lock and Sleep act on one click; the others ask for a second click.
PanelWindow {
    id: window
    property bool opened: false
    property string pending: ""
    // 0 → 1: the backdrop and the large circle; each action's travel lives in proxy.
    property real backdrop: 0
    property real hub: 0
    readonly property real d: Theme.scaleFor(screen)
    // The circle grows from the screen corner nearest the power button.
    readonly property bool mirrored: Desk.panelCenter > 0 && Desk.panelCenter < width / 2
    readonly property real cx: mirrored ? 0 : width
    readonly property real cy: 0
    readonly property real side: mirrored ? 1 : -1      // Inwards, horizontally.
    readonly property real hubRadius: 170 * d
    readonly property real orbit: 262 * d
    readonly property real dot: 70 * d
    readonly property var actions: [
        {label: "Lock", icon: "lock", confirm: false, command: [Quickshell.env("HOME") + "/.local/bin/ghost", "lock"]},
        {label: "Sleep", icon: "sleep", confirm: false, command: ["systemctl", "suspend"]},
        {label: "Log out", icon: "logout", confirm: true, command: ["hyprctl", "dispatch", "exit"]},
        {label: "Restart", icon: "restart", confirm: true, command: ["systemctl", "reboot"]},
        {label: "Shut down", icon: "power", confirm: true, command: ["systemctl", "poweroff"]}
    ]

    function sync() {
        const show = Desk.panel === "session" && Desk.panelScreen === screen.name;
        if (show === opened)
            return;
        opened = show;
        pending = "";
        if (show) {
            closing.stop();
            opening.restart();
        } else {
            opening.stop();
            closing.restart();
        }
    }
    function choose(action) {
        if (action.confirm && pending !== action.label) {
            pending = action.label;
            return;
        }
        Desk.launch(action.command);
        Desk.close();
    }
    Component.onCompleted: sync()
    Connections {
        target: Desk
        function onPanelChanged() { window.sync(); }
        function onPanelScreenChanged() { window.sync(); }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    visible: opened || backdrop > 0.001
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Opening: backdrop and circle together, then each action a beat apart.
    ParallelAnimation {
        id: opening
        NumberAnimation { target: window; property: "backdrop"; to: 1; duration: Theme.reducedMotion ? 0 : 260; easing.type: Easing.OutCubic }
        NumberAnimation { target: window; property: "hub"; to: 1; duration: Theme.reducedMotion ? 0 : 380; easing.type: Easing.OutQuint }
        SequentialAnimation {
            PauseAnimation { duration: Theme.reducedMotion ? 0 : 140 }
            NumberAnimation { target: proxy; property: "v0"; to: 1; duration: Theme.reducedMotion ? 0 : 420; easing.type: Easing.OutQuint }
        }
        SequentialAnimation {
            PauseAnimation { duration: Theme.reducedMotion ? 0 : 185 }
            NumberAnimation { target: proxy; property: "v1"; to: 1; duration: Theme.reducedMotion ? 0 : 420; easing.type: Easing.OutQuint }
        }
        SequentialAnimation {
            PauseAnimation { duration: Theme.reducedMotion ? 0 : 230 }
            NumberAnimation { target: proxy; property: "v2"; to: 1; duration: Theme.reducedMotion ? 0 : 420; easing.type: Easing.OutQuint }
        }
        SequentialAnimation {
            PauseAnimation { duration: Theme.reducedMotion ? 0 : 275 }
            NumberAnimation { target: proxy; property: "v3"; to: 1; duration: Theme.reducedMotion ? 0 : 420; easing.type: Easing.OutQuint }
        }
        SequentialAnimation {
            PauseAnimation { duration: Theme.reducedMotion ? 0 : 320 }
            NumberAnimation { target: proxy; property: "v4"; to: 1; duration: Theme.reducedMotion ? 0 : 420; easing.type: Easing.OutQuint }
        }
    }
    // Closing: everything folds back at once, a little quicker.
    ParallelAnimation {
        id: closing
        NumberAnimation { target: proxy; property: "v0"; to: 0; duration: Theme.reducedMotion ? 0 : 200; easing.type: Easing.InCubic }
        NumberAnimation { target: proxy; property: "v1"; to: 0; duration: Theme.reducedMotion ? 0 : 200; easing.type: Easing.InCubic }
        NumberAnimation { target: proxy; property: "v2"; to: 0; duration: Theme.reducedMotion ? 0 : 200; easing.type: Easing.InCubic }
        NumberAnimation { target: proxy; property: "v3"; to: 0; duration: Theme.reducedMotion ? 0 : 200; easing.type: Easing.InCubic }
        NumberAnimation { target: proxy; property: "v4"; to: 0; duration: Theme.reducedMotion ? 0 : 200; easing.type: Easing.InCubic }
        SequentialAnimation {
            PauseAnimation { duration: Theme.reducedMotion ? 0 : 80 }
            NumberAnimation { target: window; property: "hub"; to: 0; duration: Theme.reducedMotion ? 0 : 220; easing.type: Easing.InCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: Theme.reducedMotion ? 0 : 100 }
            NumberAnimation { target: window; property: "backdrop"; to: 0; duration: Theme.reducedMotion ? 0 : 220; easing.type: Easing.OutCubic }
        }
    }
    // Animatable stand-ins for the travel list (animations need plain properties).
    QtObject {
        id: proxy
        property real v0: 0
        property real v1: 0
        property real v2: 0
        property real v3: 0
        property real v4: 0
        function at(i) { return [v0, v1, v2, v3, v4][i]; }
    }

    Item {
        anchors.fill: parent
        focus: window.opened
        Keys.onEscapePressed: Desk.close()

        // Dark tint over the blur; a click anywhere outside the circles closes.
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: .38 * window.backdrop
        }
        MouseArea {
            anchors.fill: parent
            onClicked: Desk.close()
        }

        // The large circle around the power button; the screen edges cut it to a quarter.
        Rectangle {
            x: window.cx - width / 2
            y: window.cy - height / 2
            width: window.hubRadius * 2
            height: width
            radius: width / 2
            color: "#4b4b4b"
            scale: window.hub
            opacity: Math.min(1, window.hub * 1.6)
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Desk.close()
            }
        }
        // The power glyph sits inside the quarter, toward its middle.
        SvgIcon {
            id: hubIcon
            x: window.cx + window.side * .38 * window.hubRadius * window.hub - width / 2
            y: window.cy + .34 * window.hubRadius * window.hub - height / 2
            width: 42 * window.d
            height: width
            name: "power"
            opacity: window.hub
            scale: .7 + .3 * window.hub
        }
        // Icons rasterise at their on-screen size; draw them again sharp once grown.
        Connections {
            target: window
            function onHubChanged() {
                if (window.hub >= 1)
                    hubIcon.measure();
            }
        }

        Repeater {
            model: window.actions
            Item {
                id: action
                required property var modelData
                required property int index
                readonly property real t: proxy.at(index)
                onTChanged: if (t >= 1)
                    glyph.measure()
                onScaleChanged: if (t >= 1)
                    Qt.callLater(glyph.measure)
                // Angles in screen space around the corner: 172° is along the top, 98° almost straight down.
                readonly property real angle: (172 - index * 18.5) * Math.PI / 180
                readonly property real dx: Math.cos(angle) * (window.mirrored ? -1 : 1)
                readonly property real dy: Math.sin(angle)
                readonly property bool asking: window.pending === modelData.label
                // Slides from the hub's centre to the arc.
                x: window.cx + dx * window.orbit * t - width / 2
                y: window.cy + dy * window.orbit * t - height / 2
                width: window.dot
                height: window.dot
                opacity: Math.min(1, t * 2)
                scale: (.35 + .65 * t) * (area.containsMouse ? 1.06 : 1)
                Behavior on scale {
                    enabled: action.t >= 1
                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: action.asking ? "#d9d9d9" : area.containsMouse ? "#5a5a5a" : "#4b4b4b"
                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }
                }
                SvgIcon {
                    id: glyph
                    anchors.centerIn: parent
                    width: 30 * window.d
                    height: width
                    name: action.modelData.icon
                    black: action.asking
                }
                // Name below the circle while pointed at or waiting for a second click.
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 8 * window.d
                    text: action.asking ? "Click again to " + action.modelData.label.toLowerCase() : action.modelData.label
                    font.family: Theme.font
                    font.pixelSize: 13 * window.d
                    font.weight: Theme.mediumWeight
                    color: "#ffffff"
                    opacity: (area.containsMouse || action.asking) && action.t > .9 ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 140 }
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: window.opened
                    Accessible.role: Accessible.Button
                    Accessible.name: action.modelData.label
                    onClicked: window.choose(action.modelData)
                }
            }
        }
    }
}
