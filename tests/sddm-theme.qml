import QtQuick
import QtTest
import Quickshell

// Offscreen check of config/sddm/ghost/Main.qml with stand-in SDDM objects.
// Nothing here talks to the real SDDM daemon.
ShellRoot {
    QtObject {
        id: sddm
        property var calls: []
        property bool canSuspend: true
        property bool canReboot: true
        property bool canPowerOff: true
        property string hostName: "fixture"
        signal loginFailed
        signal loginSucceeded
        function login(user, password, session) { calls = calls.concat([["login", user, password, session]]); }
        function suspend() { calls = calls.concat([["suspend"]]); }
        function reboot() { calls = calls.concat([["reboot"]]); }
        function powerOff() { calls = calls.concat([["powerOff"]]); }
    }
    QtObject {
        id: userModel
        property int lastIndex: 0
        property int count: 2
        property var rows: [{ 257: "matte", 258: "", 261: true }, { 257: "guest", 258: "Guest", 261: true }]
        function index(row, column) { return row; }
        function data(row, role) { return rows[row] ? rows[row][role] : undefined; }
        function rowCount() { return rows.length; }
    }
    QtObject {
        id: sessionModel
        property int lastIndex: 0
        property var rows: ["Hyprland", "Plasma (Wayland)"]
        function index(row, column) { return row; }
        function data(row, role) { return role === 260 ? rows[row] : undefined; }
        function rowCount() { return rows.length; }
    }
    QtObject {
        id: keyboard
        property bool capsLock: false
        property int currentLayout: 0
        property var layouts: [{ shortName: "gb", longName: "English (UK)" }, { shortName: "us", longName: "English (US)" }]
    }
    QtObject {
        id: config
        function stringValue(key) { return ({ clockFormat: "HH:mm", dateFormat: "dddd, d MMMM", watermark: "true" })[key] || ""; }
    }

    FloatingWindow {
        visible: true
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#000000"
        TestCase {
            id: test
            anchors.fill: parent
            visible: true
            property bool saved: false
            Loader {
                id: loader
                anchors.fill: parent
                source: Quickshell.env("GHOST_SDDM_THEME") + "/Main.qml"
            }
            function test_theme() {
                try { check(); }
                catch (error) { console.error("FAIL! sddm theme: " + error + " " + error.stack); throw error; }
            }
            function check() {
                tryCompare(loader, "status", Loader.Ready, 3000);
                const theme = loader.item;
                wait(400);
                const capture = Quickshell.env("GHOST_SDDM_CAPTURE");
                if (capture) {
                    saved = false;
                    theme.grabToImage(r => saved = r.saveToFile(capture));
                    tryCompare(test, "saved", true, 3000);
                }
                compare(findChild(theme, "user-name").text, "matte");
                compare(findChild(theme, "pill-session").text, "Hyprland");
                compare(findChild(theme, "pill-layout").text, "English (UK)");
                compare(findChild(theme, "status").text, "Caps Lock is off");
                keyboard.capsLock = true;
                compare(findChild(theme, "status").text, "Caps Lock is on");
                keyboard.capsLock = false;

                const password = findChild(theme, "password");
                password.forceActiveFocus();
                keyClick("h"); keyClick("i");
                keyClick(Qt.Key_Return);
                compare(JSON.stringify(sddm.calls[sddm.calls.length - 1]), JSON.stringify(["login", "matte", "hi", 0]));
                sddm.loginFailed();
                wait(50);
                compare(findChild(theme, "status").text, "Incorrect password");
                compare(password.text, "");

                // Session and layout cycle on click.
                const session = findChild(theme, "pill-session");
                mouseClick(session.parent);
                compare(session.text, "Plasma (Wayland)");
                const layout = findChild(theme, "pill-layout");
                mouseClick(layout.parent);
                compare(layout.text, "English (US)");
                compare(keyboard.currentLayout, 1);
                console.info("PASS: sddm theme renders, logs in with user/password/session, reports failure, cycles session and layout");
            }
        }
    }
}
