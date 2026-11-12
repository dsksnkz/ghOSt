import QtQuick
import Quickshell

FloatingWindow {
    id: window
    title: "ghOSt Intro"
    visible: false
    readonly property real factor: Theme.scaleFor(screen)
    implicitWidth: Math.round(860 * factor)
    implicitHeight: Math.round(620 * factor)
    minimumSize: Qt.size(Math.round(760 * factor), Math.round(520 * factor))
    maximumSize: Qt.size(Math.round(1000 * factor), Math.round(760 * factor))
    color: "transparent"
    function open() { content.reset(); visible = true; }
    function capture(path) { content.grabToImage(result => result.saveToFile(path)); }
    Scaled {
        factor: window.factor
        IntroPanel {
            id: content
            anchors.fill: parent
            onCloseRequested: window.visible = false
            onActionRequested: action => {
                const screen = Quickshell.screens[0];
                if (!screen) return;
                if (action === "sidebar") Desk.toggleSidebar(screen.name);
                else if (action === "calendar") Desk.toggle("calendar", screen.name, (screen.width - Theme.calendarWidth(screen.width, screen.height)) / 2);
                else Desk.openSettings(screen.name, action);
            }
        }
    }
}
