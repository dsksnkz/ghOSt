import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    SettingsWindow {}
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: output
            required property var modelData
            Bar { id: barWindow; screen: output.modelData }
            RailReservation { screen: output.modelData }
            Panel { id: panelWindow; screen: output.modelData; companion: barWindow; managedFocus: true }
            Sidebar { id: sidebarWindow; screen: output.modelData; companion: barWindow; managedFocus: true }
            CalendarWindow { id: calendarWindow; screen: output.modelData; companion: barWindow; managedFocus: true }
            HyprlandFocusGrab {
                active: Desk.panelScreen === output.modelData.name && (Desk.sidebarOpen || Desk.panel !== "")
                windows: [barWindow, panelWindow, sidebarWindow, calendarWindow]
                onCleared: Qt.callLater(() => { if(Desk.panelScreen === output.modelData.name)Desk.close(); })
            }
        }
    }
    IpcHandler {
        target: "bar"
        function toggle(name: string): void {
            const screen = Quickshell.screens[0];
            if (screen) Desk.toggle(name, screen.name, screen.width - 420);
        }
        function close(): void { Desk.close(); }
        function sidebar(): void { const screen = Quickshell.screens[0]; if(screen)Desk.toggleSidebar(screen.name); }
        function settings(page: string): void { const screen=Quickshell.screens[0];if(screen)Desk.openSettings(screen.name,page||"general"); }
        function status(): string {
            return JSON.stringify({panel: Desk.panel, sidebar: Desk.sidebarOpen, volume: Desk.volume, network: Desk.networkName, battery: Desk.charge, workspace: Desk.activeWorkspace});
        }
    }
}
