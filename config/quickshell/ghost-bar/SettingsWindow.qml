import QtQuick
import Quickshell

FloatingWindow {
    id: window

    property string captureResult: ""

    // Capture actual native content only on pages without private lists/paths.
    // The method name stays stable for the existing captureSettings IPC.
    function captureGeneral(path) {
        const safePages = ["general", "sound", "battery", "storage", "widgets", "about", "brightness", "accessibility", "airplane", "applications"];
        const page = content.page;
        const item = content.publicCaptureItem();
        if (!visible || !safePages.includes(page) || !item) {
            captureResult = "refused: private or hidden page";
            return false;
        }
        captureResult = "pending";
        const requested = item.grabToImage((result) => {
            if (!visible || content.page !== page) {
                captureResult = "cancelled: page changed";
                return ;
            }
            captureResult = result.saveToFile(path) ? "saved" : "failed";
        });
        if (!requested)
            captureResult = "failed: renderer unavailable";

        return requested;
    }

    function inspect(action) {
        if (action === "capture")
            return captureResult;

        if (action === "sounds")
            return JSON.stringify(UiSounds.status());

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
    Component.onCompleted: Settings.active = visible
    onVisibleChanged: Settings.active = visible
    onClosed: Desk.settingsRequested = false

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

    SettingsNavigation {
        controller: Desk
        pageContent: content
        active: window.visible
    }

    SettingsPanel {
        id: content

        anchors.fill: parent
        onCloseRequested: Desk.settingsRequested = false
    }

}
