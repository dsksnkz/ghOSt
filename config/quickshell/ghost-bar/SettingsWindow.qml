import QtQuick
import Quickshell

FloatingWindow {
    id: window

    function inspect(action) {
        if (action === "polling")
            return JSON.stringify(Settings.pollingStatus());

        if (action === "portrait-general")
            content.requestPortrait("general");

        if (action === "portrait-sidebar")
            content.requestPortrait("sidebar");

        if (action === "portrait-cancel")
            content.cancelPortrait();

        if (action === "name-open")
            content.editName();

        if (action === "name-cancel")
            content.cancelName();

        return JSON.stringify({
            "windowVisible": visible,
            "content": JSON.parse(content.status())
        });
    }

    visible: Desk.settingsRequested
    title: "ghOSt Settings"
    implicitWidth: 1024
    implicitHeight: 699
    minimumSize: Qt.size(720, 490)
    color: "transparent"
    Binding {
        target: Settings
        property: "page"
        value: content.page
    }
    Binding {
        target: Desk
        property: "networkSettingsVisible"
        value: window.visible && content.page === "network"
    }
    Component.onCompleted: Settings.active = visible
    onVisibleChanged: {
        Settings.active = visible;
        if (visible)
            Qt.callLater(() => {
                content.choose(Desk.settingsPage);
                content.forceActiveFocus();
            });
    }
    onClosed: Desk.settingsRequested = false

    SettingsPanel {
        id: content

        anchors.fill: parent
        onCloseRequested: Desk.settingsRequested = false
    }
}
