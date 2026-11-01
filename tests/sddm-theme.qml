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
        property var rows: [{ 257: "matte", 258: "", 260: Quickshell.env("GHOST_SDDM_ICON") || "", 261: true }, { 257: "guest", 258: "Guest", 260: "", 261: true }]
        function index(row, column) { return row; }
        function data(row, role) { return rows[row] ? rows[row][role] : undefined; }
        function rowCount() { return rows.length; }
    }
    QtObject {
        id: sessionModel
        property int lastIndex: 2
        property var rows: ["KDE Plasma", "Niri", "Hyprland", "MangoWM", "DunnoWM"]
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
        function stringValue(key) { return ({ watermark: "true" })[key] || ""; }
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
                    findChild(theme, "password").text = "abcd";
                    wait(50);
                    const zoom = Number(Quickshell.env("GHOST_SDDM_CAPTURE_SCALE") || 1);
                    theme.grabToImage(r => saved = r.saveToFile(capture), Qt.size(theme.width * zoom, theme.height * zoom));
                    tryCompare(test, "saved", true, 3000);
                    findChild(theme, "password").text = "";
                }
                compare(theme.userName, "matte");
                compare(theme.userIcon, Quickshell.env("GHOST_SDDM_ICON") || "");
                compare(findChild(theme, "status").text, "");
                keyboard.capsLock = true;
                compare(findChild(theme, "status").text, "Caps Lock is on");
                keyboard.capsLock = false;

                const password = findChild(theme, "password");
                password.forceActiveFocus();
                keyClick("h"); keyClick("i");
                compare(findChild(theme, "password-dots").shown, 2);
                keyClick(Qt.Key_Return);
                compare(JSON.stringify(sddm.calls[sddm.calls.length - 1]), JSON.stringify(["login", "matte", "hi", 2]));
                sddm.loginFailed();
                wait(50);
                compare(findChild(theme, "status").text, "Incorrect password");
                compare(password.text, "");

                // Session list: arrows, click and clamped ends.
                compare(theme.sessionName, "Hyprland");
                keyClick(Qt.Key_Down);
                compare(theme.sessionName, "MangoWM");
                mouseClick(findChild(theme, "session-1"));
                compare(theme.sessionName, "Niri");
                keyClick(Qt.Key_Up); keyClick(Qt.Key_Up);
                compare(theme.sessionIndex, 0);
                tryCompare(theme, "sessionPosition", 0, 1000);
                compare(findChild(theme, "session-0").opacity, 1);
                // Removed by the design.
                compare(findChild(theme, "submit"), null);
                compare(findChild(theme, "clock"), null);
                // On-screen keyboard: hidden by default, toggled by its button.
                verify(!theme.keyboardOpen);
                const toggle = findChild(theme, "keyboard-toggle");
                console.info("keyboard toggle visible: " + toggle.visible);
                if (toggle.visible) {
                    mouseClick(toggle);
                    verify(theme.keyboardOpen);
                    mouseClick(toggle);
                    verify(!theme.keyboardOpen);
                }
                console.info("PASS: sddm theme renders, logs in with user/password/session, reports failure, moves through sessions");
            }
        }
    }
}
