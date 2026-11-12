import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: popup
    property var displayScreen
    screen: displayScreen
    readonly property bool showing: Notifications.toast !== null && !Notifications.dnd && displayScreen.name === (Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name)
    property real reveal: revealGate.open ? 1 : 0

    // Start the motion after the window has mapped and built its content.
    RevealGate {
        id: revealGate
        target: popup.showing
    }
    visible: showing || reveal > .001
    anchors {
        top: true
        left: true
    }
    readonly property real factor: Theme.scaleFor(screen)
    margins.top: Math.round(62 * factor)
    margins.left: Math.round((screen.width - implicitWidth) / 2)
    implicitWidth: Math.round(360 * factor)
    implicitHeight: Math.ceil((banner.implicitHeight + 8) * factor)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-notification"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Scaled {
        factor: popup.factor
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
            width: parent.width
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
    }
    Behavior on reveal {
        NumberAnimation {
            duration: Theme.reducedMotion ? 0 : 140
            easing.type: Easing.OutCubic
        }
    }
}
