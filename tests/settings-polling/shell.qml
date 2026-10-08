import QtQuick
import Quickshell
import Quickshell.Io

// Exercise the actual Settings singleton with an inert local backend, no window.
ShellRoot {
    IpcHandler {
        target: "poll-test"
        function configure(active: bool, page: string): string {
            Settings.active = false;
            Settings.page = page;
            Settings.active = active;
            return JSON.stringify(Settings.pollingStatus());
        }
        function page(page: string): string {
            Settings.page = page;
            return JSON.stringify(Settings.pollingStatus());
        }
        function status(): string {
            return JSON.stringify(Settings.pollingStatus());
        }
        function stop(): void { Qt.quit(); }
    }
}
