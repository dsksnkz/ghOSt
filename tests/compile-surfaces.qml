import QtQuick
import Quickshell

ShellRoot {
    Component.onCompleted: Qt.callLater(validate)
    function validate() {
        const files = ["SettingsPanel.qml", "SidebarFigmaBody.qml", "CalendarPanel.qml",
            "MusicBar.qml", "UiSounds.qml", "OsdState.qml", "Osd.qml", "EdgeHandle.qml", "shell.qml", "lock.qml"];
        for (const file of files) {
            const component = Qt.createComponent(Qt.resolvedUrl(file));
            if (component.status !== Component.Ready) {
                console.error(file + ": " + component.errorString());
                Qt.exit(1);
                return;
            }
        }
        console.log("PASS: production surfaces compile without instantiating windows or actions");
        Qt.quit();
    }
}
