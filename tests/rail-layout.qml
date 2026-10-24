import QtQuick
import QtTest
import Quickshell

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 1100
        implicitHeight: 920
        color: "#111111"
        TestCase {
            id: test
            anchors.fill: parent
            visible: true
            property bool saved: false
            Rail { id: rail; width: 1100; previewMode: true; screenName: "fixture" }
            SettingsPanel { id: settings; x: 36; y: 70; width: 1024; height: 699; previewMode: true }
            TopBarEditor { id: editor; x: 36; y: 70; width: 690; visible: false }
            SignalSpy { id: apply; target: editor; signalName: "applyRequested" }
            function capture(name) {
                const directory = Quickshell.env("GHOST_LAYOUT_CAPTURE_DIR");
                if (!directory) return;
                saved = false;
                settings.grabToImage(result => saved = result.saveToFile(directory + "/" + name + ".png"));
                tryCompare(test, "saved", true, 2000);
            }
            function test_customization() {
                try { checkCustomization(); }
                catch (error) { console.error("FAIL! layout: " + error + " " + error.stack); throw error; }
            }
            function dragElement(source, destination, targetX, targetY) {
                const start = source.mapToItem(test, source.width / 2, source.height / 2);
                const end = destination.mapToItem(test, targetX, targetY);
                mousePress(source, source.width / 2, source.height / 2);
                mouseMove(test, start.x + 14, start.y, 30);
                mouseMove(test, end.x, end.y, 80);
                mouseRelease(test, end.x, end.y);
                wait(100);
            }
            function checkCustomization() {
                wait(200);
                capture("settings-dark");
                settings.choose("applications");
                wait(250);
                capture("applications-top-bar");
                settings.visible = false;
                editor.visible = true;
                wait(50);
                const clockHandle = findChild(editor, "rail-drag-clock");
                const unchanged = JSON.stringify(editor.draft);
                dragElement(clockHandle, test, 1060, 850);
                compare(JSON.stringify(editor.draft), unchanged);
                const hidden = findChild(editor, "rail-drop-hidden");
                dragElement(clockHandle, hidden, hidden.width - 25, 60);
                tryCompare(editor, "dirty", true);
                compare(editor.draft.find(entry => entry.id === "clock").zone, "hidden");
                compare(apply.count, 0);
                const leftZone = findChild(editor, "rail-drop-left");
                dragElement(findChild(editor, "rail-drag-clock"), leftZone, leftZone.width - 12, 88);
                compare(editor.draft.find(entry => entry.id === "clock").zone, "left");
                keyClick(Qt.Key_Delete);
                wait(50);
                compare(editor.draft.find(entry => entry.id === "clock").zone, "hidden");
                const before = editor.draft.findIndex(entry => entry.id === "network");
                const volumeHandle = findChild(editor, "rail-drag-network");
                const networkHandle = findChild(editor, "rail-drag-bluetooth");
                dragElement(volumeHandle, networkHandle, networkHandle.width - 3, networkHandle.height / 2);
                verify(editor.draft.findIndex(entry => entry.id === "network") > before);
                mouseClick(findChild(editor, "rail-layout-apply"), 60, 18);
                compare(apply.count, 1);
                const savedLayout = JSON.parse(apply.signalArguments[0][0]);
                rail.layoutOverride = savedLayout;
                wait(30);
                compare(findChild(rail, "rail-clock-control").visible, false);
                const volume = findChild(rail, "rail-element-network");
                const network = findChild(rail, "rail-element-bluetooth");
                verify(volume.x > network.x);
                savedLayout.find(entry => entry.id === "clock").zone = "left";
                rail.layoutOverride = savedLayout.slice();
                wait(30);
                const clock = findChild(rail, "rail-clock-control");
                verify(clock.visible);
                verify(clock.x < network.x);
                mouseClick(clock, clock.width / 2, clock.height / 2);
                compare(Desk.panel, "calendar");
                Desk.close();
                rail.layoutOverride = null;
                wait(30);
                const status = rail.spacingStatus();
                verify(Math.abs(status.clockCenterX - rail.width / 2) < .01);
                console.info("PASS: dark Settings render, real drag hide and reorder, staged apply, live rail hide/move, clock action and default reset");
            }
        }
    }
}
