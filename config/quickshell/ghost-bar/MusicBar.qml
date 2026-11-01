import QtQuick
import Quickshell.Services.Mpris

// Compact rail uses real audio behind the title and transport controls.
Item {
    id: music
    property bool compact: true
    property bool active: visible
    signal expanded
    readonly property var player: Desk.player
    readonly property bool playing: Desk.playing
    property real phase: 0
    implicitHeight: compact ? 32 : 210
    AudioSpectrum {
        id: spectrum
        objectName: "music-spectrum"
        active: music.compact && music.active && music.playing && !Theme.reducedMotion
    }
    Item {
        id: background
        objectName: "music-spectrum-background"
        width: parent.width
        height: 23
        visible: music.compact && music.playing
        clip: true
        Repeater {
            model: spectrum.barCount
            G2Surface {
                required property int index
                objectName: "music-spectrum-bar-" + index
                readonly property real slotWidth: background.width / spectrum.barCount
                x: index * slotWidth + 1
                y: background.height - height
                width: Math.max(0, slotWidth - 2)
                height: Math.max(2, background.height * spectrum.levels[index])
                radius: 2
                color: "#515151"
                opacity: 0.4
                Behavior on height {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : 65 }
                }
            }
        }
    }
    function timecode(seconds) {
        return Math.floor(Math.max(0, seconds) / 60) + ":" + String(Math.floor(Math.max(0, seconds) % 60)).padStart(2, "0");
    }
    NumberAnimation on phase {
        from: 0
        to: Math.PI * 2
        duration: 1800
        loops: Animation.Infinite
        running: !music.compact && music.active && music.playing && !Theme.reducedMotion
    }
    Row {
        visible: !music.compact
        x: 0
        y: music.compact ? 6 : 24
        spacing: 2
        Repeater {
            model: 7
            G2Surface {
                required property int index
                width: 2
                height: music.playing ? 5 + 12 * (.5 + .5 * Math.sin(music.phase + index * .8)) : 3
                y: (20 - height) / 2
                radius: 1
                color: music.playing ? Theme.text : Theme.faint
            }
        }
    }
    Key {
        visible: music.compact
        y: 4
        width: 18
        height: 18
        radius: 4
        hoverFeedback: false
        hint: music.playing ? "pause" : "play"
        enabled: !!music.player?.canTogglePlaying
        onClicked: music.player.togglePlaying()
        SvgIcon {
            anchors.centerIn: parent
            width: 14
            height: 14
            name: music.playing ? "pause" : "play"
        }
    }
    Item {
        x: music.compact ? 21 : 34
        y: music.compact ? 5 : 0
        width: parent.width - (music.compact ? (music.player ? 67 : 21) : 114)
        height: music.compact ? 16 : 66
        Label {
            objectName: "music-title"
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: music.player?.trackTitle || music.player?.identity || "No playback"
            font.pixelSize: music.compact ? 12 : 18
            color: music.player ? Theme.text : Theme.muted
        }
        Key {
            anchors.fill: parent
            visible: music.compact
            hoverFeedback: false
            hint: "Media controls"
            onClicked: music.expanded()
        }
    }
    Row {
        anchors.right: parent.right
        y: music.compact ? 3 : 23
        spacing: 1
        visible: !music.compact || !!music.player
        Repeater {
            model: music.compact ? ["previous", "next"] : ["previous", music.playing ? "pause" : "play", "next"]
            Key {
                required property string modelData
                required property int index
                width: music.compact ? 22 : 25
                height: music.compact ? 20 : 25
                radius: music.compact ? 4 : 8
                hoverFeedback: !music.compact
                hint: modelData
                enabled: modelData === "previous" ? !!music.player?.canGoPrevious : modelData === "next" ? !!music.player?.canGoNext : !!music.player?.canTogglePlaying
                onClicked: modelData === "previous" ? music.player.previous() : modelData === "next" ? music.player.next() : music.player.togglePlaying()
                SvgIcon {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    name: modelData
                }
            }
        }
    }
    G2Surface {
        y: music.compact ? 23 : 93
        width: parent.width
        height: music.compact ? 1 : 5
        radius: music.compact ? 0 : 1
        color: music.compact ? "#2b2b2b" : Theme.line
        G2Surface {
            width: parent.width * (music.player?.length > 0 ? Math.max(0, Math.min(1, music.player.position / music.player.length)) : 0)
            height: parent.height
            radius: 1
            color: Theme.text
            Behavior on width {
                NumberAnimation {
                    duration: Theme.reducedMotion ? 0 : 250
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -5
            enabled: !!music.player?.canSeek && music.player?.length > 0
            onClicked: event => {
                // The input target has a 5px safety margin beyond each end.
                const fraction = (event.x - 5) / (width - 10);
                music.player.position = Math.max(0, Math.min(1, fraction)) * music.player.length;
            }
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: music.active && music.playing && !!music.player?.positionSupported
        onTriggered: music.player.positionChanged()
    }
    Column {
        visible: !music.compact
        y: 113
        width: parent.width
        spacing: 14
        Label {
            width: parent.width
            text: music.player?.trackArtist || ""
            color: Theme.muted
        }
        Row {
            width: parent.width
            Label {
                width: parent.width / 2
                text: music.timecode(music.player?.position ?? 0)
            }
            Label {
                width: parent.width / 2
                horizontalAlignment: Text.AlignRight
                text: music.timecode(music.player?.length ?? 0)
            }
        }
        Row {
            spacing: 8
            Key {
                text: "−10s"
                hint: "Seek back"
                enabled: !!music.player?.canSeek
                onClicked: music.player.seek(-10)
            }
            Key {
                text: "+10s"
                hint: "Seek forward"
                enabled: !!music.player?.canSeek
                onClicked: music.player.seek(10)
            }
            Key {
                text: "Stop"
                hint: "Stop playback"
                enabled: !!music.player?.canControl
                onClicked: music.player.stop()
            }
            Label {
                width: Math.max(0, music.width - 195)
                text: music.player?.identity || "MPRIS"
                color: Theme.muted
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
