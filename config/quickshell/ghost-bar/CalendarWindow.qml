import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Separately deployable calendar: other installed panels keep their existing code.
PanelWindow {
    id: window
    property var companion
    property var peers: []
    property bool managedFocus: false
    property bool opened: false
    function sync() { opened = Desk.panel === "calendar" && Desk.panelScreen === screen.name; }
    Component.onCompleted: sync()
    Connections {
        target: Desk
        function onPanelChanged() { window.sync(); }
        function onPanelScreenChanged() { window.sync(); }
    }
    property real reveal: opened ? 1 : 0
    readonly property real designScale: screen.width / 1920
    anchors { top: true; left: true }
    margins.top: 82 * designScale
    margins.left: Math.round((screen.width-implicitWidth)/2)
    implicitWidth: Math.floor(Math.min(screen.width*806.3/1920, (screen.height-100)*806.3/310))
    implicitHeight: Math.round(implicitWidth*310/806.3)
    color: "transparent"
    visible: opened || reveal > .001
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on reveal { NumberAnimation { duration:Theme.reducedMotion?0:260; easing.type:Easing.OutCubic } }
    onOpenedChanged: {
        if(opened)Qt.callLater(()=>{ frame.forceActiveFocus(); if(!window.managedFocus)grab.active=true; });
        else if(!window.managedFocus)grab.active=false;
    }
    HyprlandFocusGrab { id:grab; windows:window.peers.length?[window].concat(window.peers):window.companion?[window,window.companion]:[window]; onCleared: Qt.callLater(()=>{if(!window.managedFocus && window.opened)Desk.close();}) }
    G2Surface {
        id:frame
        anchors.fill:parent
        radius:Theme.outerRadius * window.designScale; color:"#151515"; border.color:"#474747"
        gradient:Gradient {
            GradientStop { position:0; color:"#161616" }
            GradientStop { position:1; color:"#1c1c1c" }
        }
        opacity:window.reveal
        transform:Translate { y:-28*(1-window.reveal) }
        Keys.onEscapePressed: {
            if(search.active)search.active=false;
            else if(calendar.actionPage!=="")calendar.actionPage="";
            else Desk.close();
        }
        CalendarPanel {
            id:calendar; anchors.fill:parent; active:window.opened
            onNavigateRequested: page => {
                if(page === "launcher") { search.active=true; Qt.callLater(()=>search.item?.focusSearch()); }
                else if(page === "settings") Desk.openSettings(screen.name);
                else if(page === "session") Desk.toggle("session", screen.name, Math.max(6, screen.width-410), screen.width-36);
            }
        }
        Loader {
            id:search; active:false
            anchors.centerIn:parent; width:392; height:480
            sourceComponent: G2Surface {
                color:Theme.surface; radius:10; border.color:Theme.line
                function focusSearch(){ launcher.focusSearch(); }
                Key { x:344;y:8;width:32;height:28;text:"×";hint:"Close applications";onClicked:search.active=false }
                Launcher { id:launcher;x:22;y:40;width:348 }
            }
        }
    }
    onVisibleChanged: if(!visible)search.active=false
}
