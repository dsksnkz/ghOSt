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

        if (action === "wallpaper-open")
            content.openWallpaperPicker();

        return JSON.stringify({
            "windowVisible": visible,
            "content": JSON.parse(content.status())
        });
    }

    // Ctrl+scroll, Ctrl+plus and Ctrl+minus change this, on top of the
    // monitor-proportional shell scale; it is saved when the zoom settles.
    property real userZoom: Settings.state.preferences?.settingsZoom || 1
    readonly property real zoom: Theme.scaleFor(screen) * userZoom

    function setZoom(value) {
        const next = Math.round(Math.max(0.75, Math.min(1.5, value)) * 20) / 20;
        if (next === userZoom)
            return;
        userZoom = next;
        // Grow the window when the larger controls no longer fit its width.
        implicitWidth = Math.max(width, Math.round(content.minimumWidth * zoom));
        implicitHeight = Math.max(height, Math.round(content.minimumHeight * zoom));
        saveZoom.restart();
    }

    visible: Desk.settingsRequested
    title: "ghOSt Settings"
    implicitWidth: Math.round(1024 * zoom)
    implicitHeight: Math.round(699 * zoom)
    minimumSize: Qt.size(Math.round(content.minimumWidth * zoom), Math.round(content.minimumHeight * zoom))
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

    Timer {
        id: saveZoom
        interval: 500
        onTriggered: Settings.preference("settingsZoom", window.userZoom.toFixed(2))
    }

    SettingsPanel {
        id: content

        anchors.fill: parent
        zoom: window.zoom
        onCloseRequested: Desk.settingsRequested = false
    }

    // Above the pages without taking clicks; plain scrolling still reaches the lists.
    Item {
        anchors.fill: parent
        z: 1000
        WheelHandler {
            acceptedModifiers: Qt.ControlModifier
            onWheel: event => {
                window.setZoom(window.userZoom + (event.angleDelta.y > 0 ? 0.05 : event.angleDelta.y < 0 ? -0.05 : 0));
                event.accepted = true;
            }
        }
    }

    Shortcut {
        sequences: ["Ctrl++", "Ctrl+="]
        onActivated: window.setZoom(window.userZoom + 0.05)
    }

    Shortcut {
        sequence: "Ctrl+-"
        onActivated: window.setZoom(window.userZoom - 0.05)
    }

    Shortcut {
        sequence: "Ctrl+0"
        onActivated: window.setZoom(1)
    }

}
