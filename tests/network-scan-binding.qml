import QtQuick
import Quickshell
import Quickshell.Io
import "NetworkScanPolicy.js" as ScanPolicy

// Windowless Qt binding regression. No Networking import or system actions.
ShellRoot {
    id: root
    property QtObject firstAdapter: QtObject { property bool scannerEnabled: false }
    property QtObject secondAdapter: QtObject { property bool scannerEnabled: false }
    property var device: firstAdapter
    property bool wifiEnabled: true
    property string panel: ""
    property bool sidebarOpen: false
    property bool sidebarNetworkEnabled: true
    property bool settingsOpen: false
    property string settingsPage: "general"
    readonly property bool requested: ScanPolicy.shouldScan({
        wifiAvailable: device !== null,
        wifiEnabled: wifiEnabled,
        panel: panel,
        sidebarOpen: sidebarOpen,
        sidebarNetworkEnabled: sidebarNetworkEnabled,
        networkSettingsVisible: settingsOpen && settingsPage === "network"
    })
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: root.requested
        when: root.device !== null
    }
    IpcHandler {
        target: "scan-test"
        function configure(parameters: string): string {
            const state = JSON.parse(parameters);
            root.wifiEnabled = state.wifiEnabled ?? true;
            root.panel = state.panel ?? "";
            root.sidebarOpen = state.sidebarOpen ?? false;
            root.sidebarNetworkEnabled = state.sidebarNetworkEnabled ?? true;
            root.settingsOpen = state.settingsOpen ?? false;
            root.settingsPage = state.settingsPage ?? "general";
            root.device = state.device === "none" ? null
                : state.device === "second" ? root.secondAdapter : root.firstAdapter;
            return JSON.stringify({
                requested: root.requested,
                first: root.firstAdapter.scannerEnabled,
                second: root.secondAdapter.scannerEnabled
            });
        }
        function stop(): void { Qt.quit(); }
    }
}
