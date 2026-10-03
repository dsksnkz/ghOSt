import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: bar
    property var monitor: null
    property var trayWindow: null
    property string screenName: ""
    property bool previewMode: false
    implicitHeight: 64
    readonly property real designScale: width/1920
    FontLoader { id: clockFace; source: "fonts/TurretRoad-Bold.ttf" }
    FontLoader { id: dateFace; source: "fonts/TurretRoad-Regular.ttf" }
    function open(name, item) {
        const center=item.mapToItem(bar,item.width/2,0).x;
        Desk.toggle(name,screenName,Math.max(6,Math.min(width-398,center-196)),center);
    }
    Item {
        width: 1920; height: 64; scale: bar.designScale; transformOrigin: Item.TopLeft
        Material {
            x: 19; y: 16; width: 1882; height: 46
            radius: 7; gradient: null; color: "#2b2b2b"; border.width: 0
            G2Surface {
                anchors.fill: parent; anchors.margins: -1
                radius: 8; color: "transparent"; border.color: "#4d4d4d"; border.width: 1
            }
            Key {
                x: 19; y: 7; width: 42; height: 32; hint: "Open controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                SvgIcon { x: 10; y: 4; width: 24; height: 24; name: "menu" }
            }
            Workspaces { x: 132; y: 0; monitor: bar.monitor }
            Key {
                x: 314; y: 7; width: 260; height: 32; hint: "Media controls"
                onClicked: bar.open("media",this)
                onSecondaryClicked: if(Desk.player?.canTogglePlaying)Desk.player.togglePlaying()
                SvgIcon { x: 14; y: 6; width: 14; height: 14; name: Desk.playing?"pause":"play"; opacity: Desk.playing?1:.4 }
                Label { x: 42; y: 7; width: 210; text: Desk.player?.trackTitle || "NO PLAYBACK"; font.pixelSize: 10; color: Desk.player?Theme.text:Theme.faint }
                G2Surface { x: 14; y: 27; width: 247; height: 1; color: "#323232" }
            }
            Key {
                x: 872; y: 5; width: 180; height: 36; hint: "Calendar"
                onClicked: bar.open("calendar",this)
                SvgIcon { x: 0; y: 6; width: 19; height: 20; name: "calendar" }
                Label { x: 27; y: 4; width: 78; height: 28; text: Qt.formatDateTime(Desk.now,"HH:mm"); font.family: clockFace.name; font.pixelSize: 26; font.weight: Font.Bold; color: "#ffffff" }
                G2Surface { x: 105; y: 0; width: 1; height: 36; color: "#ffffff" }
                Label { x: 125; y: 2; width: 39; height: 16; text: Qt.formatDateTime(Desk.now,"MM.dd"); font.family: dateFace.name; font.pixelSize: 15; color: "#ffffff" }
                SvgIcon { x: 125; y: 18; width: 11; height: 16; name: Desk.weatherSummary.condition==="clear"?"brightness":Desk.weatherSummary.condition==="unknown"?"cloud":Desk.weatherSummary.condition }
                Label { x: 139; y: 18; width: 36; height: 16; text: typeof Desk.weatherSummary.temperature==="number"?Math.round(Desk.weatherSummary.temperature)+"°":"—"; font.family: dateFace.name; font.pixelSize: 15; color: "#ffffff" }
            }
            Key {
                x: 1473; y: 7; width: 100; height: 32; hint: "Sound"
                onClicked: bar.open("audio",this)
                onSecondaryClicked: Desk.mute()
                onScrolled: delta => Desk.setVolume((Desk.volume+(delta>0?2:-2))/100)
                SvgIcon { x: 0; y: 6; width: 17; height: 17; name: Desk.muted?"mute":"volume" }
                Meter { x: 30; y: 10; count: 7; segmentWidth: 3; spacing: 3; value: Desk.muted?0:Desk.volume/100 }
                Label { x: 80; y: 9; width: 26; text: Desk.volume; font.pixelSize: 10; color: Theme.muted }
            }
            Key {
                x: 1621; y: 7; width: 41; height: 32; hint: "Network controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                SvgIcon { x: 10; y: 6; width: 21; height: 21; name: Desk.wired?"ethernet":"wifi"; opacity: Desk.connected?1:.45 }
            }
            Key {
                x: 1673; y: 7; width: 41; height: 32; hint: "Bluetooth controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                SvgIcon { x: 10; y: 6; width: 21; height: 21; name: "bluetooth"; opacity: Desk.adapter?.enabled?1:.45 }
            }
            Key {
                x: 1726; y: 7; width: 71; height: 32; hint: "Battery controls"
                onClicked: Desk.toggleSidebar(bar.screenName)
                Label { x: 0; y: 5; width: 38; height: 22; text: Desk.hasBattery?Desk.charge+"%":"AC"; font.pixelSize: 12; font.weight: Font.Bold; color: "#ffffff" }
                SvgIcon { x: 41; y: 5; width: 30; height: 22; name: "battery"; visible: Desk.hasBattery || bar.previewMode }
            }
            Key {
                x: 1837; y: 7; width: 39; height: 32; hint: "Power"
                onClicked: bar.open("session",this)
                Canvas {
                    x:0; y:-4; width:39; height:39
                    onPaint: { const c=getContext("2d"),g=c.createRadialGradient(19.5,19.5,1,19.5,19.5,18); c.clearRect(0,0,width,height);g.addColorStop(0,"rgba(255,255,255,.19)");g.addColorStop(1,"rgba(255,255,255,0)");c.fillStyle=g;c.fillRect(0,0,width,height); }
                }
                SvgIcon { x: 10; y: 7; width: 19; height: 18; name: "power" }
            }
        }
    }
}
