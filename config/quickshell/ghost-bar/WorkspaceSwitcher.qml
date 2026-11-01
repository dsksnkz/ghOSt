import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Super+Tab workspace overview for one output.
PanelWindow {
    id: window
    property bool opened: false
    function sync() {
        opened = Desk.switcherScreen !== "" && Desk.switcherScreen === screen.name;
    }
    Component.onCompleted: sync()
    visible: scene.shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ghost-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    Connections {
        target: Desk
        function onSwitcherScreenChanged() {
            window.sync();
        }
        function onSwitcherConfirmed() {
            if (window.opened)
                scene.confirm();
        }
        function onSwitcherStepped(direction) {
            if (window.opened)
                scene.step(direction);
        }
    }
    SwitcherScene {
        id: scene
        anchors.fill: parent
        open: window.opened
        monitor: Hyprland.monitorFor(window.screen)
        onChosen: workspace => Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspace + " })")
        onMagicChosen: special => Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"" + special + "\")")
        onClosed: Desk.closeSwitcher()
    }
}
