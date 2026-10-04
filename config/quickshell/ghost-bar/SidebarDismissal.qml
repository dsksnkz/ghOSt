import QtQuick
import Quickshell
import Quickshell.Wayland

// A temporary transparent pointer surface, with holes for every open control.
// Does not depend on a compositor focus grab competing with another shell.
PanelWindow {
    id: dismissal
    required property var sidebarWindow
    required property var calendarWindow
    required property var panelWindow
    required property var railWindow
    required property var notificationWindow
    visible: sidebarWindow.opened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-sidebar-dismissal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    mask: Region {
        width: dismissal.width
        height: dismissal.height
        Region {
            width: dismissal.width
            height: dismissal.railWindow.height
            intersection: Intersection.Subtract
        }
        Region {
            x: dismissal.sidebarWindow.margins.left
            y: dismissal.sidebarWindow.margins.top
            width: dismissal.sidebarWindow.width
            height: dismissal.sidebarWindow.height
            intersection: Intersection.Subtract
        }
        Region {
            x: dismissal.calendarWindow.margins.left
            y: dismissal.calendarWindow.margins.top
            width: dismissal.calendarWindow.opened ? dismissal.calendarWindow.width : 0
            height: dismissal.calendarWindow.opened ? dismissal.calendarWindow.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            x: dismissal.panelWindow.margins.left
            y: dismissal.panelWindow.margins.top
            width: dismissal.panelWindow.opened ? dismissal.panelWindow.width : 0
            height: dismissal.panelWindow.opened ? dismissal.panelWindow.height : 0
            intersection: Intersection.Subtract
        }
        Region {
            x: dismissal.notificationWindow.margins.left
            y: dismissal.notificationWindow.margins.top
            width: dismissal.notificationWindow.visible ? dismissal.notificationWindow.width : 0
            height: dismissal.notificationWindow.visible ? dismissal.notificationWindow.height : 0
            intersection: Intersection.Subtract
        }
    }
    DismissArea {
        anchors.fill: parent
        onDismissed: Desk.close()
    }
}
