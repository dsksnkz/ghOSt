import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.UPower

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 392
        implicitHeight: 90
        color: "#191919"
        TestCase {
            id: test
            anchors.fill: parent
            visible: true
            property string requested: ""
            property bool saved: false
            PowerProfileControls { id: liveObserver; visible: false }
            PowerProfileControls {
                id: controls
                x: 16; y: 16; width: parent.width - 32
                previewMode: true
                onProfileRequested: profile => test.requested = profile
            }
            function test_buttons() {
                wait(100);
                if (Quickshell.env("GHOST_EXPECT_SAVER"))
                    tryCompare(liveObserver, "activeProfile", PowerProfile.PowerSaver, 2000);
                mouseClick(findChild(controls, "power-profile-power-saver"));
                compare(requested, "power-saver");
                compare(controls.activeProfile, PowerProfile.PowerSaver);
                wait(100);
                const directory = Quickshell.env("GHOST_POWER_CAPTURE_DIR");
                if (directory) {
                    test.grabToImage(result => saved = result.saveToFile(directory + "/power-controls.png"));
                    tryCompare(test, "saved", true, 1500);
                }
                mouseClick(findChild(controls, "power-profile-balanced"));
                compare(requested, "balanced");
                compare(controls.activeProfile, PowerProfile.Balanced);
                mouseClick(findChild(controls, "power-profile-performance"));
                compare(requested, "performance");
                compare(controls.activeProfile, PowerProfile.Performance);
                controls.previewPerformanceAvailable = false;
                verify(!findChild(controls, "power-profile-performance").enabled);
                requested = "";
                controls.choose("performance", PowerProfile.Performance);
                compare(requested, "");
                compare(controls.busy, false);
                console.info("PASS: three profile buttons, normal mapping, observed selection and unavailable performance guard; no live changes");
            }
        }
    }
}
