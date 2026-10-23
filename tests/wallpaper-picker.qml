import QtQuick
import QtTest
import Quickshell

ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 960
        implicitHeight: 600
        color: "#151515"
        TestCase {
            id: test
            anchors.fill: parent
            visible: true
            property bool saved: false
            WallpaperPicker { id: picker; x: 30; y: 30 }
            SignalSpy { id: chosen; target: picker; signalName: "imageChosen" }
            readonly property string fixture: Quickshell.env("GHOST_PICKER_FIXTURE")

            function findEntry(name) {
                const view = findChild(picker.contentItem, "wallpaper-files");
                for (let i = 0; i < view.count; ++i) {
                    const item = view.itemAtIndex(i);
                    if (item && item.fileName === name)
                        return item;
                }
                fail("Missing entry: " + name);
            }

            function test_browser() {
                try {
                    runBrowser();
                } catch (error) {
                    console.error("FAIL! wallpaper picker: " + error + " " + error.stack);
                    throw error;
                }
            }
            function runBrowser() {
                compare(picker.localUrl("/Images/a #1?.webp"), "file:///Images/a%20%231%3F.webp");
                picker.browse("");
                picker.navigate(fixture);
                tryCompare(picker, "fileCount", 4, 3000);
                wait(100);
                const view = findChild(picker.contentItem, "wallpaper-files");
                const apply = findChild(picker.contentItem, "wallpaper-apply");
                verify(!apply.enabled);

                const image = findEntry("Coast #1.webp");
                mouseClick(image, 180, image.height / 2);
                tryCompare(picker, "imageReady", true, 3000);
                compare(picker.selectedName, "Coast #1.webp");
                compare(chosen.count, 0);
                verify(apply.enabled);
                verify(picker.selectedFile.toString().includes("%23"));

                const directory = Quickshell.env("GHOST_PICKER_CAPTURE_DIR");
                if (directory) {
                    picker.contentItem.grabToImage(result => saved = result.saveToFile(directory + "/wallpaper-picker.png"));
                    tryCompare(test, "saved", true, 2000);
                }

                keyClick(Qt.Key_Down);
                tryCompare(picker, "selectedName", "Night.webp");
                keyClick(Qt.Key_Up);
                tryCompare(picker, "selectedName", "Coast #1.webp");
                tryCompare(picker, "imageReady", true, 3000);
                mouseClick(apply, apply.width / 2, apply.height / 2);
                compare(chosen.count, 1);
                tryCompare(picker, "visible", false);

                picker.browse(fixture + "/Night.webp");
                tryCompare(picker, "imageReady", true, 3000);
                keyClick(Qt.Key_Escape);
                tryCompare(picker, "visible", false);
                compare(chosen.count, 1);
                compare(picker.selectedFile.toString(), "");

                picker.browse("");
                picker.navigate(fixture);
                tryCompare(picker, "fileCount", 4, 3000);
                wait(100);
                const broken = findEntry("Broken.jpg");
                mouseClick(broken, 180, broken.height / 2);
                wait(100);
                verify(!picker.imageReady);
                verify(!apply.enabled);
                picker.confirmSelection();
                compare(chosen.count, 1);
                const folder = findEntry("Empty folder");
                mouseDoubleClickSequence(folder, 180, folder.height / 2);
                tryCompare(picker, "fileCount", 0, 3000);
                verify(!picker.imageReady);
                compare(picker.selectedFile.toString(), "");
                picker.close();
                console.info("PASS: dark wallpaper browser, thumbnails, preview, keyboard, folders, explicit apply and safe cancel");
            }
        }
    }
}
