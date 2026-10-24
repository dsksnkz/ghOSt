import QtQuick
import Quickshell

FloatingWindow {
    id: window
    title: "ghOSt Intro"
    visible: false
    implicitWidth: 860
    implicitHeight: 620
    minimumSize: Qt.size(760, 520)
    maximumSize: Qt.size(1000, 760)
    color: "transparent"
    function open() { content.reset(); visible = true; }
    function capture(path) { content.grabToImage(result => result.saveToFile(path)); }
    IntroPanel {
        id: content
        anchors.fill: parent
        onCloseRequested: window.visible = false
        onActionRequested: action => {
            const screen = Quickshell.screens[0];
            if (!screen) return;
            if (action === "sidebar") Desk.toggleSidebar(screen.name);
            else if (action === "calendar") Desk.toggle("calendar", screen.name, (screen.width - 820) / 2);
            else Desk.openSettings(screen.name, action);
        }
    }
}
