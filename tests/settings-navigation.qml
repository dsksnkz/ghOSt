import QtQuick
import Quickshell
import Quickshell.Io

// Actual nonvisual router, inert controller/content, no system-service imports.
ShellRoot {
    id: root
    property QtObject controller: QtObject {
        property string settingsPage: "general"
        signal settingsNavigationRequested
        function request(page) {
            settingsPage = page;
            settingsNavigationRequested();
        }
    }
    property QtObject content: QtObject {
        property string page: "general"
        property int choices: 0
        property int focuses: 0
        function choose(value) { page = value; choices++; }
        function forceActiveFocus() { focuses++; }
    }
    SettingsNavigation {
        id: navigation
        controller: root.controller
        pageContent: root.content
    }
    IpcHandler {
        target: "navigation-test"
        function configure(parameters: string): void {
            const state = JSON.parse(parameters);
            if (state.active !== undefined)
                navigation.active = state.active;
            if (state.localPage !== undefined)
                root.content.page = state.localPage;
            for (const page of state.requests || [])
                root.controller.request(page);
            if (state.closeBeforeRoute)
                navigation.active = false;
        }
        function status(): string {
            return JSON.stringify({
                active: navigation.active,
                page: root.content.page,
                choices: root.content.choices,
                focuses: root.content.focuses
            });
        }
        function stop(): void { Qt.quit(); }
    }
}
