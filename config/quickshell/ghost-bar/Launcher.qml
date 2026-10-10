import QtQuick
import QtQuick.Controls as Controls
import QtCore
import Quickshell
import "LauncherSearch.js" as Search

Item {
    id: launcher
    property bool previewMode: false
    property alias query: search.text
    property string lastRequest: ""
    readonly property var pins: Search.readPins(preferences.pinnedIds)
    readonly property bool commandMode: Search.commandMode(query)
    readonly property var results: {
        if (!commandMode)
            return Search.ranked(DesktopEntries.applications.values, query, pins);
        const entry = Search.commandEntry(query);
        return entry ? [entry] : [];
    }
    implicitHeight: 296
    signal closeRequested
    function navigateKey(event) {
        if (event.key === Qt.Key_Escape) {
            keyboardScroll.stop();
            query = "";
            lastRequest = "";
            closeRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            move(event.key === Qt.Key_Down ? 1 : -1);
            event.accepted = true;
        }
    }
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => navigateKey(event)

    function focusSearch() { search.forceActiveFocus(); }
    function beginSession() {
        keyboardScroll.stop();
        query = "";
        lastRequest = "";
        list.currentIndex = results.length ? 0 : -1;
        list.contentY = list.originY;
        focusSearch();
    }
    function move(delta) {
        if (!results.length) return;
        list.currentIndex = Math.max(0, Math.min(results.length - 1, list.currentIndex + delta));
        const top = list.originY + list.currentIndex * (48 + list.spacing);
        const bottom = top + 48;
        let target = list.contentY;
        if (top < target) target = top;
        else if (bottom > target + list.height) target = bottom - list.height;
        target = Math.max(list.originY, Math.min(list.originY + Math.max(0, list.contentHeight - list.height), target));
        // Retarget from the current frame when keys repeat; never snap the
        // viewport with positionViewAtIndex while the outline is animating.
        keyboardScroll.stop();
        if (Theme.reducedMotion)
            list.contentY = target;
        else {
            keyboardScroll.to = target;
            keyboardScroll.start();
        }
    }
    function pin(entry) {
        if (!entry || entry.terminalCommand) return;
        preferences.pinnedIds = JSON.stringify(pins.includes(entry.id) ? pins.filter(id => id !== entry.id) : [...pins, entry.id]);
    }
    function launch(entry) {
        if (!entry) return;
        lastRequest = entry.id;
        if (previewMode) return;
        if (entry.terminalCommand)
            Desk.launch(Search.commandArgs(entry.terminalCommand));
        else
            entry.execute();
        Desk.close();
    }
    function status() {
        return JSON.stringify({query, count: results.length,
            selected: results[list.currentIndex]?.id || "", pins, lastRequest});
    }
    onResultsChanged: {
        keyboardScroll.stop();
        list.currentIndex = results.length ? 0 : -1;
        list.contentY = list.originY;
    }
    NumberAnimation {
        id: keyboardScroll
        target: list
        property: "contentY"
        duration: 220
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.2, 0.75, 0.25, 1, 1, 1]
    }
    Component.onCompleted: Qt.callLater(focusSearch)
    Settings {
        id: preferences
        location: "file://" + (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/ghost/launcher.ini"
        property string pinnedIds: "[]"
    }
    G2Surface {
        width: parent.width
        height: 44
        radius: 16
        smoothing: 0.6
        color: "#252525"
        Icon {
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 23; height: 23
            name: "search"
            ink: "#858585"
        }
        Controls.TextField {
            id: search
            x: 64
            width: parent.width - 80
            height: parent.height
            padding: 0
            color: Theme.text
            placeholderText: "Search"
            placeholderTextColor: "#858585"
            font.family: Theme.textFont
            font.pixelSize: 18
            selectByMouse: true
            selectionColor: Theme.text
            selectedTextColor: Theme.base
            background: Item {}
            Accessible.name: "Search applications or > followed by a background command"
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => launcher.navigateKey(event)
            Keys.onReturnPressed: launcher.launch(launcher.results[list.currentIndex])
            Keys.onEnterPressed: launcher.launch(launcher.results[list.currentIndex])
        }
    }
    ListView {
        id: list
        objectName: "launcher-list"
        y: 56
        width: parent.width
        // Whole rows only: preserve a bottom breathing margin rather than
        // showing a cropped fifth icon beneath the four visible results.
        height: Math.max(48, Math.floor((parent.height - y - 16 + spacing) / (48 + spacing)) * (48 + spacing) - spacing)
        clip: true
        spacing: 8
        model: launcher.results
        currentIndex: 0
        boundsBehavior: Flickable.StopAtBounds
        onMovementStarted: keyboardScroll.stop()
        keyNavigationEnabled: false
        highlightFollowsCurrentItem: false
        highlight: G2Surface {
            objectName: "launcher-selection"
            y: list.originY + Math.max(0, list.currentIndex) * (48 + list.spacing)
            width: list.width
            height: 48
            radius: 16
            smoothing: 0.6
            color: "transparent"
            border.width: 1
            border.color: "#555555"
            Behavior on y {
                NumberAnimation {
                    duration: Theme.reducedMotion ? 0 : 220
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.2, 0.75, 0.25, 1, 1, 1]
                }
            }
        }
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool chosen: ListView.isCurrentItem
            width: list.width
            height: 48
            Key {
                id: rowKey
                width: parent.width
                height: parent.height
                radius: 16
                smoothing: 0.6
                color: "transparent"
                hoverFeedback: false
                hint: row.modelData.name
                onClicked: {
                    list.currentIndex = row.index;
                    launcher.launch(row.modelData);
                }
                Image {
                    id: appIcon
                    x: 20
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32
                    source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                    sourceSize: Qt.size(32 * Screen.devicePixelRatio, 32 * Screen.devicePixelRatio)
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                Icon {
                    x: 20
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32
                    visible: appIcon.status !== Image.Ready
                    name: Search.iconFor(row.modelData)
                    ink: Theme.text
                }
                Label {
                    x: 76
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - 54
                    text: row.modelData.name
                    font.family: Theme.textFont
                    font.pixelSize: 18
                    color: Theme.text
                    elide: Text.ElideRight
                }
            }
            Key {
                id: pinKey
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 34; height: 34
                visible: !row.modelData.terminalCommand && (rowKey.hovered || hovered)
                color: "transparent"
                hint: launcher.pins.includes(row.modelData.id) ? "Unpin application" : "Pin application"
                onClicked: launcher.pin(row.modelData)
                Icon {
                    anchors.centerIn: parent
                    name: "pin"
                    ink: Theme.text
                    opacity: launcher.pins.includes(row.modelData.id) ? 1 : 0.3
                }
            }
        }
        Label {
            anchors.centerIn: parent
            visible: !launcher.results.length
            text: launcher.commandMode ? "Enter a command after >" : "No matching applications"
            color: Theme.muted
        }
        Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded; width: 3 }
    }
}
