import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Separately deployable calendar: other installed panels keep their existing code.
PanelWindow {
    id: window
    property var companion
    property bool opened: false
    function sync() { opened = Desk.panel === "calendar" && Desk.panelScreen === screen.name; }
    Component.onCompleted: sync()
    Connections {
        target: Desk
        function onPanelChanged() { window.sync(); }
        function onPanelScreenChanged() { window.sync(); }
    }
    property real reveal: opened ? 1 : 0
    anchors { top: true; left: true }
    margins.top: 82
    margins.left: Math.round((screen.width-implicitWidth)/2)
    implicitWidth: Math.floor(Math.min(screen.width*733/1920, (screen.height-100)*1200/505))
    implicitHeight: implicitWidth*505/1200
    color: "transparent"
    visible: opened || reveal > .001
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on reveal { NumberAnimation { duration:Theme.reducedMotion?0:260; easing.type:Easing.OutCubic } }
    onOpenedChanged: {
        if(opened)Qt.callLater(()=>{ frame.forceActiveFocus(); grab.active=true; });
        else grab.active=false;
    }
    HyprlandFocusGrab { id:grab; windows:window.companion?[window,window.companion]:[window]; onCleared: Qt.callLater(()=>{if(window.opened)Desk.close();}) }
    Rectangle {
        id:frame
        anchors.fill:parent; anchors.margins:1
        radius:Theme.outerRadius; color:"#151515"; border.color:"#454545"
        gradient:Gradient {
            GradientStop { position:0; color:"#151515" }
            GradientStop { position:.72; color:"#202020" }
            GradientStop { position:1; color:"#171717" }
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
            sourceComponent: Rectangle {
                color:Theme.surface; radius:10; border.color:Theme.line
                function focusSearch(){ launcher.focusSearch(); }
                Key { x:344;y:8;width:32;height:28;text:"×";hint:"Close applications";onClicked:search.active=false }
                Launcher { id:launcher;x:22;y:40;width:348 }
            }
        }
    }
    onVisibleChanged: if(!visible)search.active=false
}
