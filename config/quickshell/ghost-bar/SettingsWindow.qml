import QtQuick
import Quickshell

FloatingWindow {
    id:window
    visible:Desk.settingsRequested
    title:"ghOSt Settings"
    implicitWidth:1024;implicitHeight:699
    minimumSize:Qt.size(720,490)
    color:"transparent"
    Component.onCompleted:Settings.active=visible
    onVisibleChanged: { Settings.active=visible;if(visible)Qt.callLater(()=>{content.choose(Desk.settingsPage);content.forceActiveFocus();}); }
    onClosed:Desk.settingsRequested=false
    SettingsPanel { id:content;anchors.fill:parent;onCloseRequested:Desk.settingsRequested=false }
}
