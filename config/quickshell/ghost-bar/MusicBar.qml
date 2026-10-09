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
        anchors.fill: parent
        visible: music.compact
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
                opacity: music.playing ? 0.65 : 0.25
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
    Item {
        x: music.compact ? 6 : 34
        width: parent.width - (music.compact ? 86 : 114)
        height: music.compact ? 29 : 66
        Label {
            objectName: "music-title"
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: music.player?.trackTitle || "No playback"
            font.pixelSize: music.compact ? 13 : 18
            color: music.player ? Theme.text : Theme.muted
        }
        Key {
            anchors.fill: parent
            visible: music.compact
            hint: "Media controls"
            onClicked: music.expanded()
        }
    }
    Row {
        anchors.right: parent.right
        y: music.compact ? 4 : 23
        spacing: 1
        Repeater {
            model: ["previous", music.playing ? "pause" : "play", "next"]
            Key {
                required property string modelData
                required property int index
                width: 25
                height: 25
                radius: 8
                hint: modelData
                enabled: index === 0 ? !!music.player?.canGoPrevious : index === 2 ? !!music.player?.canGoNext : !!music.player?.canTogglePlaying
                onClicked: index === 0 ? music.player.previous() : index === 2 ? music.player.next() : music.player.togglePlaying()
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
        y: music.compact ? 30 : 93
        width: parent.width
        height: music.compact ? 2 : 5
        radius: 1
        color: Theme.line
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
                UiSounds.play("rail");
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
