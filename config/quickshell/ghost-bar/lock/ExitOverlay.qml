import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: overlay
    property bool begin: false
    property bool reducedMotion: false
    property real opening: 0
    signal prepared
    signal finished
    visible: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "ghost-lock-exit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Timer {
        id: prepare
        interval: 50
        running: overlay.width > 0 && overlay.height > 0
        onTriggered: overlay.prepared()
    }
    onBeginChanged: if (begin)
        rotation.start()
    NumberAnimation {
        id: rotation
        target: overlay
        property: "opening"
        to: 1
        duration: overlay.reducedMotion ? 0 : 680
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.2, 0.7, 0.2, 1, 1, 1]
        onFinished: overlay.finished()
    }
    Blinds {
        anchors.fill: parent
        opening: overlay.opening
    }
}
