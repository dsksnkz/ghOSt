import QtQuick
import Quickshell.Hyprland
import Quickshell

Item {
    id: wheel
    property var monitor
    property int fixtureWorkspace: -1
    readonly property int current: fixtureWorkspace>0 ? fixtureWorkspace : Math.max(1,monitor?.activeWorkspace?.id ?? Desk.activeWorkspace)
    property int previous: current
    function scroll(delta) {
        Quickshell.execDetached(["python3",Quickshell.shellPath("workspace_scroll.py"),delta>0?"-1":"1",String(Math.max(1,Math.round(Math.abs(delta)/120)))]);
    }
    width: 99; height: 46
    onCurrentChanged: {
        slide.from = current>previous ? 36 : -36;
        previous=current;
        if(!Theme.reducedMotion)slide.restart();
    }
    Item {
        id: track; width: parent.width; height: parent.height
        NumberAnimation { id: slide; target: track; property: "x"; to: 0; duration: 170; easing.type: Easing.OutCubic }
        Repeater {
            model: [-1,0,1]
            Key {
                required property int modelData
                readonly property int workspace: wheel.current+modelData
                readonly property bool central: modelData===0
                x: modelData<0?0:modelData===0?36:76
                width: 23; height: 46; enabled: workspace>0
                color: "transparent"; hint: "Workspace "+workspace
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = "+workspace+" })")
                onScrolled: delta => wheel.scroll(delta)
                Label { x: 0; y: parent.central?10:16; width: 23; height: 18; horizontalAlignment:Text.AlignHCenter; text: workspace>0?String(workspace).padStart(2,"0"):""; font.family:Theme.font; font.pixelSize: parent.central?15:11; font.weight: parent.central?Font.Bold:Font.Medium; color: parent.central?"#ffffff":"#b8b8b8" }
            }
        }
    }
    Canvas {
        x: 36+(23-width)/2; y: 29; width: 14; height: 6
        onPaint: { const c=getContext("2d"); c.reset(); c.beginPath(); c.moveTo(0,6); c.lineTo(7,0); c.lineTo(14,6); c.closePath(); c.fillStyle="#b8b8b8"; c.fill(); }
    }
}
