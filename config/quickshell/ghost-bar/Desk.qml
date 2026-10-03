pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris

Singleton {
    id: root
    property string panel: ""
    property string panelScreen: ""
    property real panelX: 0
    property real panelOrigin: 196
    property string notice: ""
    property string performanceMetric: "cpu"
    property var weatherSummary: ({condition:"unknown", temperature:null})
    property bool sidebarOpen: false
    property bool settingsRequested: false
    property string settingsPage: "general"
    function toggleSidebar(screenName) { panelScreen=screenName; settingsRequested=false; sidebarOpen = !sidebarOpen; }
    function openSettings(screenName, page="general") { panelScreen=screenName; panel=""; sidebarOpen=false; settingsPage=page; settingsRequested=true; }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio?.muted ?? false
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int charge: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property string networkName: wired ? "Ethernet" : network ? network.name : Networking.wifiEnabled ? "Not connected" : "Wi-Fi off"
    readonly property bool connected: !!wired || !!network
    readonly property var player: Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing) ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing
    readonly property var now: clock.date
    readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? 1
    property SystemClock clock: SystemClock { precision: SystemClock.Seconds }
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    function toggle(name, screenName, x, center) {
        if (!["launcher", "audio", "calendar", "network", "bluetooth", "battery", "media", "session"].includes(name)) return;
        if (panel === name && panelScreen === screenName) { close(); return; }
        panelScreen = screenName;
        panelX = x;
        panelOrigin = center === undefined ? 196 : Math.max(18, Math.min(374, center - x));
        notice = "";
        panel = name;
    }
    function close() { panel = ""; sidebarOpen = false; settingsRequested=false; }
    function setVolume(value) { if (audio) audio.volume = Math.max(0, Math.min(1, value)); }
    function mute() { if (audio) audio.muted = !audio.muted; }
    function launch(args) { close(); Quickshell.execDetached(args); }
    function setPerformanceMetric(value) { performanceMetric = value; }
    onPanelChanged: if (wifi) wifi.scannerEnabled = panel === "network";
}
