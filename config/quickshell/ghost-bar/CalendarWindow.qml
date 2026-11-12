import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Separately deployable calendar: other installed panels keep their existing code.
PanelWindow {
    id: window
    property var companion
    property var peers: []
    property bool managedFocus: false
    property bool opened: false
    function renderingStatus() {
        return calendar.renderingStatus();
    }
    function forecastStep(step) {
        if (opened)
            calendar.selectForecast(calendar.forecastIndex + step);
        return JSON.stringify({
            condition: calendar.headlineCondition,
            temperature: calendar.headlineTemperature,
            index: calendar.forecastIndex
        });
    }
    function sync() {
        opened = Desk.panel === "calendar" && Desk.panelScreen === screen.name;
    }
    Component.onCompleted: sync()
    Connections {
        target: Desk
        function onPanelChanged() {
            window.sync();
        }
        function onPanelScreenChanged() {
            window.sync();
        }
    }
    property real reveal: revealGate.open ? 1 : 0

    // Start the motion after the window has mapped and built its content.
    RevealGate {
        id: revealGate
        target: window.opened
    }
    readonly property real designScale: Theme.scaleFor(screen)
    anchors {
        top: true
        left: true
    }
    margins.top: 68 * designScale
    margins.left: Math.round((screen.width - implicitWidth) / 2)
    implicitWidth: Theme.calendarWidth(screen.width, screen.height)
    implicitHeight: Math.round(implicitWidth * Theme.calendarPlaneHeight / Theme.calendarPlaneWidth)
    color: "transparent"
    visible: opened || reveal > .001
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on reveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : 150
            easing.type: Easing.OutCubic
        }
    }
    onOpenedChanged: {
        if (opened)
            Qt.callLater(() => {
                frame.forceActiveFocus();
                if (!window.managedFocus)
                    grab.active = true;
            });
        else if (!window.managedFocus)
            grab.active = false;
    }
    HyprlandFocusGrab {
        id: grab
        windows: window.peers.length ? [window].concat(window.peers) : window.companion ? [window, window.companion] : [window]
        onCleared: Qt.callLater(() => {
            if (!window.managedFocus && window.opened)
                Desk.close();
        })
    }
    G2Surface {
        id: frame
        anchors.fill: parent
        radius: Theme.outerRadius * window.designScale
        color: "#0b0b0b"
        border.color: "#272727"
        border.width: 1
        opacity: window.reveal
        // Machined top edge: a faint highlight inside the outline.
        Rectangle {
            x: frame.radius
            y: 1
            width: frame.width - 2 * frame.radius
            height: 1
            color: "#ffffff"
            opacity: .06
        }
        transform: Translate {
            y: -16 * (1 - window.reveal)
        }
        Keys.onEscapePressed: {
            if (calendar.actionPage !== "")
                calendar.actionPage = "";
            else
                Desk.close();
        }
        CalendarPanel {
            id: calendar
            anchors.fill: parent
            // Subframe reveal and telemetry begin with the frame motion, not during window setup.
            active: window.opened && revealGate.open
            onNavigateRequested: page => {
                if (page === "launcher")
                    Desk.toggle("launcher", screen.name, 0);
                else if (page === "settings")
                    Desk.openSettings(screen.name);
                else if (page === "session")
                    Desk.toggle("session", screen.name, Math.max(6, screen.width - 410 * window.designScale), screen.width - 36 * window.designScale);
            }
        }
    }
}
