import QtQuick
import QtTest
import Quickshell

ShellRoot {
    FloatingWindow {
        visible: true
        implicitWidth: 860
        implicitHeight: 620
        IntroPanel { id: intro; anchors.fill: parent }
        SignalSpy { id: actions; target: intro; signalName: "actionRequested" }
        SignalSpy { id: closes; target: intro; signalName: "closeRequested" }
        TestCase {
            name: "Intro"
            anchors.fill: parent
            visible: true
            function test_search_and_action() {
                wait(150);
                compare(intro.results.length, 7);
                compare(intro.selected.id, "start");
                const search = findChild(intro, "intro-search");
                mouseClick(search, 30, 20);
                for (const key of [Qt.Key_E, Qt.Key_T, Qt.Key_H, Qt.Key_E, Qt.Key_R, Qt.Key_N, Qt.Key_E, Qt.Key_T])
                    keyClick(key);
                compare(intro.results.length, 1);
                compare(intro.selected.id, "connections");
                mouseClick(findChild(intro, "intro-open-action"), 50, 18);
                compare(actions.count, 1);
                compare(actions.signalArguments[0][0], "network");
                search.text = "not-a-real-topic";
                compare(intro.results.length, 0);
                compare(intro.selected, null);
                intro.reset();
                compare(intro.query, "");
                compare(intro.selected.id, "start");
                search.forceActiveFocus();
                keyClick(Qt.Key_Escape);
                compare(closes.count, 1);
                const capture = Quickshell.env("GHOST_INTRO_CAPTURE");
                if (capture) {
                    intro.grabToImage(result => result.saveToFile(capture));
                    wait(250);
                }
                console.log("PASS: Intro real keyboard search, empty/reset state, explicit action and Escape");
            }
        }
    }
}
