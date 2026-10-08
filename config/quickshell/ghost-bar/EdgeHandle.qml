import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// One left-edge target. Its input region expands only while hovered.
PanelWindow {
    id: edge
    implicitWidth: 30
    implicitHeight: 100
    anchors {
        top: true
        left: true
    }
    margins.top: Math.round((screen.height - implicitHeight) / 2)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-left-edge"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    visible: !Desk.sidebarOpen && !Desk.settingsRequested && !(Hyprland.focusedMonitor?.activeWorkspace?.hasFullscreen ?? false)
    mask: Region {
        width: hit.containsMouse ? 30 : 3
        height: edge.height
    }
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            UiSounds.play("sidebar");
            Desk.toggleSidebar(edge.screen.name);
        }
        G2Surface {
            x: hit.containsMouse ? 6 : 0
            y: 18
            width: hit.containsMouse ? 22 : 2
            height: 64
            radius: hit.containsMouse ? 8 : 1
            color: "#383838"
            opacity: hit.containsMouse ? 1 : .2
            Behavior on x {
                NumberAnimation {
                    duration: Theme.reducedMotion ? 0 : 180
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: Theme.reducedMotion ? 0 : 180
                }
            }
            SvgIcon {
                anchors.centerIn: parent
                width: 14
                height: 14
                name: "ghost"
                opacity: hit.containsMouse ? 1 : 0
            }
        }
    }
}
