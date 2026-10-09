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

    readonly property bool mediaOpened: panelWindow.opened && panelWindow.page === "media"
    property int presses: 0
    function status() {
        return {
            visible,
            width,
            height,
            inputWidth: input.width,
            inputHeight: input.height,
            presses
        };
    }
    visible: sidebarWindow.opened || calendarWindow.opened || mediaOpened
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

    DismissArea {
        id: input
        anchors.fill: parent
        onDismissed: {
            dismissal.presses++;
            Desk.close();
        }
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
            width: dismissal.sidebarWindow.opened ? dismissal.sidebarWindow.width : 0
            height: dismissal.sidebarWindow.opened ? dismissal.sidebarWindow.height : 0
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
            width: dismissal.mediaOpened ? dismissal.panelWindow.width : 0
            height: dismissal.mediaOpened ? dismissal.panelWindow.height : 0
            intersection: Intersection.Subtract
        }
    }
}
