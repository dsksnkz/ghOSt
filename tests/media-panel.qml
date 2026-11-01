import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.Mpris

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 420
        implicitHeight: 296
        color: "#0b0b0b"
        TestCase {
            id: test
            visible: true
            anchors.fill: parent
            property bool saved: false
            Rectangle {
                id: stage
                width: 420
                height: 296
                color: "#0b0b0b"
                MediaPanel { id: panel; anchors.fill: parent; active: true }
            }
            function test_panel() {
                wait(300);
                const player = panel.player;
                compare(findChild(panel, "media-title").text, "Midnight City");
                compare(findChild(panel, "media-artist").text, "M83");
                compare(findChild(panel, "media-position").text, "1:28");
                compare(findChild(panel, "media-length").text, "4:03");
                compare(panel.implicitHeight, 296);
                const spectrum = panel.children.find(child => child.barCount !== undefined) || panel.resources.find(child => child.barCount !== undefined);
                spectrum.levels = [.9, .7, .8, .5, .6, .85, .4, .7, .5, .3, .6, .4, .3, .2, .25];
                wait(200);
                for (let i = 0; i < 12; i++)
                    fuzzyCompare(panel.level(i), panel.level(24 - i), .0001);
                fuzzyCompare(panel.level(0), .9, .0001);
                fuzzyCompare(panel.level(12), .25, .0001);
                const directory = Quickshell.env("GHOST_MEDIA_CAPTURE_DIR");
                if (directory) {
                    stage.grabToImage(result => saved = result.saveToFile(directory + "/media.png"));
                    tryCompare(test, "saved", true, 2000);
                }
                mouseClick(findChild(panel, "media-previous"));
                mouseClick(findChild(panel, "media-next"));
                mouseClick(findChild(panel, "media-toggle"));
                compare(player.calls.join(), "previous,next,toggle");
                mouseClick(findChild(panel, "media-shuffle"));
                compare(player.shuffle, true);
                mouseClick(findChild(panel, "media-repeat"));
                compare(player.loopState, MprisLoopState.Playlist);
                const seek = findChild(panel, "media-seek");
                mouseClick(seek, seek.width / 2, seek.height / 2);
                fuzzyCompare(player.position, 121.5, .5);
                console.info("PASS: media panel track, mirrored spectrum, transport, shuffle, repeat and seek");
            }
        }
    }
}
