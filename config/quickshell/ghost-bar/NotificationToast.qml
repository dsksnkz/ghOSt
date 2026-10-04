import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: popup
    property var displayScreen
    screen: displayScreen
    readonly property bool showing: Notifications.toast !== null && !Notifications.dnd && displayScreen.name === (Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name)
    property real reveal: showing ? 1 : 0
    visible: showing || reveal > .001
    anchors {
        top: true
        left: true
    }
    margins.top: 76
    margins.left: Math.round((screen.width - implicitWidth) / 2)
    implicitWidth: 360
    implicitHeight: banner.implicitHeight + 8
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-notification"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    NotificationBanner {
        id: banner
        property var retained: null
        Connections {
            target: Notifications
            function onToastChanged() {
                if (Notifications.toast)
                    banner.retained = Notifications.toast;
            }
        }
        notification: Notifications.toast || retained
        width: popup.width
        height: implicitHeight
        opacity: popup.reveal
        transform: Translate {
            y: -8 * (1 - popup.reveal)
        }
        onActivated: {
            Desk.toggleSidebar(popup.displayScreen.name);
            Notifications.toast = null;
        }
        onDismissed: Notifications.toast = null
    }
    Behavior on reveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : 140
            easing.type: Easing.OutCubic
        }
    }
}
