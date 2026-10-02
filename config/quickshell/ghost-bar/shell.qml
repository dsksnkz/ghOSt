import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: output
            required property var modelData
            Bar { id: barWindow; screen: output.modelData }
            Panel { screen: output.modelData; companion: barWindow }
            Sidebar { screen: output.modelData; companion: barWindow }
            CalendarWindow { screen: output.modelData; companion: barWindow }
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
        function status(): string {
            return JSON.stringify({panel: Desk.panel, volume: Desk.volume, network: Desk.networkName, battery: Desk.charge, workspace: Desk.activeWorkspace});
        }
    }
}
