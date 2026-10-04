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
    readonly property var results: Search.ranked(DesktopEntries.applications.values, query, pins)
    implicitHeight: 428
    function focusSearch() {
        search.forceActiveFocus();
    }
    function move(delta) {
        if (!results.length)
            return;
        list.currentIndex = Math.max(0, Math.min(results.length - 1, list.currentIndex + delta));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }
    function pin(entry) {
        if (!entry)
            return;
        preferences.pinnedIds = JSON.stringify(pins.includes(entry.id) ? pins.filter(id => id !== entry.id) : [...pins, entry.id]);
    }
    function launch(entry) {
        if (!entry)
            return;
        lastRequest = entry.id;
        if (previewMode)
            return;
        entry.execute();
        Desk.close();
    }
    function status() {
        return JSON.stringify({
            query,
            count: results.length,
            selected: results[list.currentIndex]?.id || "",
            pins,
            lastRequest
        });
    }
    onResultsChanged: list.currentIndex = results.length ? 0 : -1
    Component.onCompleted: Qt.callLater(focusSearch)
    Settings {
        id: preferences
        location: "file://" + (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/ghost/launcher.ini"
        property string pinnedIds: "[]"
    }
    Column {
        anchors.fill: parent
        spacing: 16
        G2Surface {
            width: parent.width
            height: 44
            radius: 5
            color: Theme.base
            border.color: search.activeFocus ? Theme.muted : Theme.line
            Icon {
                x: 13
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
            }
            Controls.TextField {
                id: search
                x: 42
                width: parent.width - 50
                height: parent.height
                padding: 0
                color: Theme.text
                placeholderText: "Find an application"
                placeholderTextColor: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
                selectByMouse: true
                selectionColor: Theme.text
                selectedTextColor: Theme.base
                background: Item {}
                Accessible.name: "Find an application"
                Keys.onDownPressed: launcher.move(1)
                Keys.onUpPressed: launcher.move(-1)
                Keys.onReturnPressed: launcher.launch(launcher.results[list.currentIndex])
                Keys.onEnterPressed: launcher.launch(launcher.results[list.currentIndex])
            }
        }
        Row {
            width: parent.width
            Label {
                width: parent.width - 50
                text: launcher.query.trim() ? "RESULTS" : "APPLICATIONS"
                font.pixelSize: 9
                font.letterSpacing: 1
                color: Theme.muted
            }
            Label {
                width: 50
                horizontalAlignment: Text.AlignRight
                text: String(launcher.results.length).padStart(2, "0")
                font.pixelSize: 9
                color: Theme.muted
            }
        }
        ListView {
            id: list
            width: parent.width
            height: 300
            clip: true
            spacing: 4
            model: launcher.results
            currentIndex: 0
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 90
            highlight: G2Surface {
                radius: 5
                color: Theme.text
            }
            keyNavigationEnabled: false
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool chosen: ListView.isCurrentItem
                readonly property color ink: chosen ? Theme.base : Theme.text
                width: list.width
                height: 46
                Key {
                    width: parent.width - 38
                    height: parent.height
                    color: "transparent"
                    hint: "Open " + row.modelData.name
                    onClicked: {
                        list.currentIndex = row.index;
                        launcher.launch(row.modelData);
                    }
                    Icon {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        name: Search.iconFor(row.modelData)
                        ink: row.ink
                    }
                    Column {
                        x: 44
                        width: parent.width - 52
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Label {
                            width: parent.width
                            text: row.modelData.name
                            color: row.ink
                            font.pixelSize: 12
                        }
                        Label {
                            width: parent.width
                            visible: text !== ""
                            text: row.modelData.genericName
                            color: row.chosen ? "#484848" : Theme.muted
                            font.pixelSize: 9
                        }
                    }
                }
                Key {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34
                    color: "transparent"
                    hint: launcher.pins.includes(row.modelData.id) ? "Unpin application" : "Pin application"
                    onClicked: launcher.pin(row.modelData)
                    Icon {
                        anchors.centerIn: parent
                        name: "pin"
                        ink: row.ink
                        opacity: launcher.pins.includes(row.modelData.id) ? 1 : .3
                    }
                }
            }
            Column {
                anchors.centerIn: parent
                spacing: 16
                visible: !launcher.results.length
                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "search"
                    width: 28
                    height: 28
                    ink: Theme.muted
                }
                Label {
                    text: "No matching applications"
                    color: Theme.muted
                }
            }
            Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
                width: 3
                contentItem: G2Surface {
                    color: Theme.muted
                    radius: 1
                }
            }
        }
        Label {
            text: "↑ ↓  SELECT     ↵  OPEN     ESC  CLOSE"
            font.pixelSize: 9
            color: Theme.muted
        }
    }
}
