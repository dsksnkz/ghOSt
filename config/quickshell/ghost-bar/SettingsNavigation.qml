import QtQuick

// Route every open request, including requests for an already visible window.
QtObject {
    id: navigation
    required property QtObject controller
    required property QtObject pageContent
    property bool active: false

    function routePage() {
        if (!active)
            return;
        pageContent.choose(controller.settingsPage);
        pageContent.forceActiveFocus();
    }
    // The same deferred function coalesces rapid requests to their latest page.
    onActiveChanged: if (active)
        Qt.callLater(routePage)
    Component.onCompleted: if (active)
        Qt.callLater(routePage)

    property Connections requests: Connections {
        target: navigation.controller
        function onSettingsNavigationRequested() {
            Qt.callLater(navigation.routePage);
        }
    }
}
