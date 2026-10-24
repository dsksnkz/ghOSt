import QtQuick
import QtQuick.Controls as Controls
import "IntroTopics.js" as Topics

G2Surface {
    id: intro
    color: "#111111"
    radius: 12
    border.color: "#383838"
    border.width: 1
    property string query: ""
    property string selectedId: "start"
    readonly property var results: Topics.search(query)
    readonly property var selected: results.find(topic => topic.id === selectedId) || results[0] || null
    signal actionRequested(string action)
    signal closeRequested
    function reset() { query = ""; selectedId = "start"; search.text = ""; }
    Keys.onEscapePressed: closeRequested()
    focus: true

    SvgIcon { x: 24; y: 25; width: 30; height: 30; name: "ghost" }
    Label { x: 68; y: 24; text: "ghOSt Intro"; font.pixelSize: 22; font.weight: Theme.demiWeight }
    Label { x: 68; y: 55; text: "Desktop basics"; color: "#aaaaaa"; font.pixelSize: 12 }
    Key {
        x: parent.width - 56; y: 20; width: 32; height: 32; hint: "Close introduction"
        onClicked: intro.closeRequested()
        SvgIcon { anchors.centerIn: parent; width: 20; height: 20; name: "close" }
    }
    G2Surface {
        x: 24; y: 94; width: parent.width - 48; height: 42; radius: 8; color: "#222222"
        SvgIcon { x: 13; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; name: "search" }
        Controls.TextField {
            id: search
            objectName: "intro-search"
            x: 44; width: parent.width - 54; height: parent.height
            placeholderText: "Search tutorials and settings"
            placeholderTextColor: "#aaaaaa"
            color: "#f2f2f2"; selectionColor: "#666666"; selectedTextColor: "white"
            font.family: Theme.font; font.pixelSize: 13
            background: Item {}
            onTextChanged: intro.query = text
            Keys.onEscapePressed: intro.closeRequested()
        }
    }
    Label {
        x: 24; y: 158
        text: intro.query ? "Search results" : "Recommended first"
        color: "#aaaaaa"; font.pixelSize: 11
    }
    Controls.ScrollView {
        x: 24; y: 182; width: 254; height: parent.height - 206
        contentWidth: availableWidth
        clip: true
        Column {
            width: parent.width
            spacing: 6
            Repeater {
                model: intro.results
                Key {
                    required property var modelData
                    objectName: "intro-topic-" + modelData.id
                    width: 250; height: 54; radius: 8
                    selected: intro.selected?.id === modelData.id
                    color: selected ? "#333333" : "transparent"
                    hint: modelData.title
                    onClicked: intro.selectedId = modelData.id
                    SvgIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; name: modelData.icon }
                    Label {
                        x: 44; anchors.verticalCenter: parent.verticalCenter; width: 190
                        text: modelData.title; font.pixelSize: 12; color: "#f2f2f2"
                    }
                }
            }
            Label { visible: intro.results.length === 0; text: "No matching tutorials"; color: "#bbbbbb" }
        }
    }
    G2Surface {
        x: 298; y: 158; width: parent.width - 322; height: parent.height - 182
        radius: 10; color: "#191919"
        Controls.ScrollView {
            x: 24; y: 24; width: parent.width - 48; height: parent.height - 48
            contentWidth: availableWidth
            clip: true
            Column {
                width: parent.width
                spacing: 22
                SvgIcon { width: 36; height: 36; name: intro.selected?.icon || "search" }
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone
                    text: intro.selected?.title || "No results"; font.pixelSize: 25; font.weight: Theme.demiWeight
                }
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone
                    text: intro.selected?.summary || "Try a different word."; font.pixelSize: 14; color: "#cccccc"
                }
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone
                    text: intro.selected?.body || ""; font.pixelSize: 13; lineHeight: 1.4; color: "#bbbbbb"
                }
                Key {
                    objectName: "intro-open-action"
                    visible: !!intro.selected?.action
                    text: intro.selected?.button || ""; color: "#dedede"; ink: "#111111"; height: 36
                    onClicked: intro.actionRequested(intro.selected.action)
                }
            }
        }
    }
}
