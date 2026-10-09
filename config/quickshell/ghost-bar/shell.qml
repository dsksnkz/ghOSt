import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    Component.onCompleted: UiSounds.status()
    // Native development must not leave Quickshell's generic reload panel over
    // the desktop. Errors remain in the runtime log; these are not OSD messages.
    Connections {
        target: Quickshell
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }
        function onReloadFailed(errorString) {
            Quickshell.inhibitReloadPopup();
        }
    }
    SettingsWindow {
        id: settingsWindow
    }
    Variants {
        id: outputs
        model: Quickshell.screens
        delegate: Scope {
            id: output
            required property var modelData
            readonly property var sidebarSurface: sidebarWindow
            readonly property var calendarSurface: calendarWindow
            readonly property var panelSurface: panelWindow
            readonly property var dismissalSurface: dismissalWindow
            property int focusRevision: 0
            property int focusDismissals: 0
            // Sidebar uses OnDemand layer focus: include it in this group so
            // Escape remains usable without trapping outside pointer events.
            // Media transport does not need a compositor keyboard grab.
            readonly property bool wantsFocus: Desk.panelScreen === modelData.name && (Desk.sidebarOpen || (Desk.panel !== "" && Desk.panel !== "media"))
            function refreshFocus() {
                focusRevision++;
                if (wantsFocus)
                    focusDelay.restart();
                else
                    focusDelay.stop();
                focusGrab.active = false;
            }
            Connections {
                target: Desk
                function onPanelChanged() {
                    output.refreshFocus();
                }
                function onSidebarOpenChanged() {
                    output.refreshFocus();
                }
                function onPanelScreenChanged() {
                    output.refreshFocus();
                }
            }
            Timer {
                id: focusDelay
                interval: 50
                onTriggered: if (output.wantsFocus)
                    focusGrab.active = true
            }
            Bar {
                id: barWindow
                screen: output.modelData
            }
            RailReservation {
                screen: output.modelData
            }
            Osd {
                screen: output.modelData
            }
            EdgeHandle {
                screen: output.modelData
            }
            NotificationToast {
                id: toastWindow
                displayScreen: output.modelData
            }
            Panel {
                id: panelWindow
                screen: output.modelData
                companion: barWindow
                managedFocus: true
            }
            Sidebar {
                id: sidebarWindow
                screen: output.modelData
                companion: barWindow
                managedFocus: true
            }
            SidebarDismissal {
                id: dismissalWindow
                screen: output.modelData
                sidebarWindow: output.sidebarSurface
                calendarWindow: output.calendarSurface
                panelWindow: output.panelSurface
                railWindow: barWindow
                notificationWindow: toastWindow
            }
            CalendarWindow {
                id: calendarWindow
                screen: output.modelData
                companion: barWindow
                managedFocus: true
            }
            HyprlandFocusGrab {
                id: focusGrab
                windows: [barWindow, panelWindow, sidebarWindow, calendarWindow]
                onCleared: {
                    const revision = output.focusRevision;
                    if (focusDelay.running)
                        return;
                    Qt.callLater(() => {
                        if (revision === output.focusRevision && output.wantsFocus && !focusDelay.running && !Desk.settingsRequested) {
                            output.focusDismissals++;
                            Desk.close();
                        }
                    });
                }
            }
        }
    }
    IpcHandler {
        target: "bar"
        function toggle(name: string): void {
            const screen = Quickshell.screens[0];
            if (screen)
                Desk.toggle(name, screen.name, screen.width - 420);
        }
        function close(): void {
            Desk.close();
        }
        function sidebar(): void {
            const screen = Quickshell.screens[0];
            if (screen)
                Desk.toggleSidebar(screen.name);
        }
        function settings(page: string): void {
            const screen = Quickshell.screens[0];
            if (screen)
                Desk.openSettings(screen.name, page || "general");
        }
        function osd(kind: string): void {
            OsdState.request(kind);
        }
        function forecast(step: int): string {
            const output = outputs.instances.find(output => output.calendarSurface.opened);
            return output ? output.calendarSurface.forecastStep(step) : "{}";
        }
        function dismissal(): string {
            return JSON.stringify(Array.from(outputs.instances, output => Object.assign(output.dismissalSurface.status(), {
                    focusDismissals: output.focusDismissals
                })));
        }
        function settingsFlow(action: string): string {
            return settingsWindow.inspect(action);
        }
        function notifications(): string {
            return JSON.stringify({
                ready: Notifications.ready,
                mode: Notifications.mode,
                count: Notifications.count,
                dnd: Notifications.dnd,
                error: Notifications.error
            });
        }
        // No SSIDs, credentials or connection actions in scanner diagnostics.
        function networkScan(): string {
            return JSON.stringify(Desk.networkScanStatus());
        }
        function dismissNotification(key: string): void {
            Notifications.dismiss(key);
        }
        function status(): string {
            return JSON.stringify({
                panel: Desk.panel,
                sidebar: Desk.sidebarOpen,
                settings: Desk.settingsRequested,
                volume: Desk.volume,
                network: Desk.networkName,
                battery: Desk.charge,
                workspace: Desk.activeWorkspace
            });
        }
        // Read-only native diagnostics: verification needs no substitute UI.
        function rendering(): string {
            return JSON.stringify(Array.from(outputs.instances, output => ({
                        screen: output.modelData.name,
                        calendar: output.calendarSurface.renderingStatus()
                    })));
        }
    }
}
