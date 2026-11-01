import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris

// Popup opened from the rail's audio element: track, artwork, transport and seek
// over the live spectrum.
Item {
    id: media
    property bool active: false
    readonly property var player: Desk.player
    readonly property bool playing: Desk.playing
    readonly property real length: player?.length > 0 ? player.length : 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, (player?.position ?? 0) / length)) : 0
    readonly property bool hasArt: art.status === Image.Ready
    readonly property bool repeatOne: player?.loopState === MprisLoopState.Track
    readonly property bool repeating: repeatOne || player?.loopState === MprisLoopState.Playlist
    readonly property int centerX: width / 2
    implicitHeight: 296

    function timecode(seconds) {
        return Math.floor(Math.max(0, seconds) / 60) + ":" + String(Math.floor(Math.max(0, seconds) % 60)).padStart(2, "0");
    }
    // Mirrored around the artwork, bass outermost so it stays visible beside the cover.
    function level(index) {
        const side = (bars.count - 1) / 2;
        const position = (1 - Math.abs(index - side) / side) * (spectrum.barCount - 1);
        const low = Math.floor(position);
        const high = Math.min(spectrum.barCount - 1, low + 1);
        return spectrum.levels[low] + (spectrum.levels[high] - spectrum.levels[low]) * (position - low);
    }
    function status() {
        return JSON.stringify({
            title: title.text,
            playing: playing,
            hasArt: hasArt,
            spectrum: spectrum.active,
            progress: progress
        });
    }

    AudioSpectrum {
        id: spectrum
        active: media.active && media.playing && !Theme.reducedMotion
    }
    Timer {
        interval: 1000
        repeat: true
        running: media.active && media.playing && !!media.player?.positionSupported
        onTriggered: media.player.positionChanged()
    }

    Item {
        id: barField
        anchors.fill: parent
        layer.enabled: true
        layer.textureSize: Qt.size(width / 2, height / 2)
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: .8
            blurMax: 32
        }
        Repeater {
            id: bars
            model: 25
            Rectangle {
                required property int index
                objectName: "media-spectrum-bar"
                readonly property real slot: (barField.width - 32) / bars.count
                x: 16 + index * slot + (slot - width) / 2
                y: barField.height - 6 - height
                width: 9
                height: Math.max(6, 180 * media.level(index))
                color: "#5c5c5c"
                Behavior on height {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : 65 }
                }
            }
        }
    }

    Label {
        id: title
        objectName: "media-title"
        x: 20
        y: 20
        width: parent.width - 40
        horizontalAlignment: Text.AlignHCenter
        text: media.player?.trackTitle || "Nothing playing"
        font.pixelSize: 15
        font.weight: media.player ? Theme.mediumWeight : Font.Normal
        color: media.player ? Theme.text : Theme.muted
    }
    Label {
        objectName: "media-artist"
        x: 20
        y: 42
        width: parent.width - 40
        horizontalAlignment: Text.AlignHCenter
        text: media.player?.trackArtist || ""
        font.pixelSize: 12
        color: Theme.muted
    }

    // Artwork doubles as the play/pause control.
    G2Surface {
        id: artFrame
        x: media.centerX - width / 2
        y: 70
        width: 132
        height: 132
        radius: 12
        color: "#151515"
        G2Image {
            id: art
            objectName: "media-art"
            anchors.fill: parent
            radius: parent.radius
            source: media.player?.trackArtUrl || ""
        }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#000000"
            opacity: media.hasArt && (artKey.hovered || !media.playing) ? .4 : 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.fast }
            }
        }
        SvgIcon {
            anchors.centerIn: parent
            width: 30
            height: 30
            name: media.playing ? "pause" : "play"
            opacity: !media.hasArt || artKey.hovered || !media.playing ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.fast }
            }
        }
        Key {
            id: artKey
            objectName: "media-toggle"
            anchors.fill: parent
            radius: parent.radius
            hoverFeedback: false
            hint: media.playing ? "Pause" : "Play"
            enabled: !!media.player?.canTogglePlaying
            onClicked: media.player.togglePlaying()
        }
    }

    Repeater {
        model: [
            {id: "previous", side: -1},
            {id: "next", side: 1}
        ]
        Key {
            required property var modelData
            objectName: "media-" + modelData.id
            x: media.centerX + modelData.side * 136 - width / 2
            y: 116
            width: 40
            height: 40
            radius: 20
            hint: modelData.id
            enabled: modelData.side < 0 ? !!media.player?.canGoPrevious : !!media.player?.canGoNext
            onClicked: modelData.side < 0 ? media.player.previous() : media.player.next()
            SvgIcon {
                anchors.centerIn: parent
                width: 26
                height: 26
                name: parent.modelData.id
            }
        }
    }
    Key {
        objectName: "media-shuffle"
        x: media.centerX - 136 - width / 2
        y: 160
        width: 28
        height: 28
        radius: 14
        hint: "Shuffle"
        enabled: !!media.player?.shuffleSupported
        onClicked: media.player.shuffle = !media.player.shuffle
        SvgIcon {
            anchors.centerIn: parent
            width: 16
            height: 16
            name: "shuffle"
            opacity: media.player?.shuffle ? 1 : .5
        }
    }
    Key {
        objectName: "media-repeat"
        x: media.centerX + 136 - width / 2
        y: 160
        width: 28
        height: 28
        radius: 14
        hint: "Repeat"
        enabled: !!media.player?.loopSupported
        onClicked: media.player.loopState = !media.repeating ? MprisLoopState.Playlist : media.repeatOne ? MprisLoopState.None : MprisLoopState.Track
        SvgIcon {
            anchors.centerIn: parent
            width: 16
            height: 16
            name: media.repeatOne ? "repeat-one" : "repeat"
            opacity: media.repeating ? 1 : .5
        }
    }

    Label {
        objectName: "media-position"
        x: 8
        y: 252
        width: 42
        height: 20
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
        text: media.timecode(media.player?.position ?? 0)
        font.pixelSize: 11
    }
    Rectangle {
        id: track
        x: 58
        y: 258
        width: parent.width - 116
        height: 8
        radius: 4
        color: "#2e2e2e"
        Rectangle {
            width: Math.max(media.progress > 0 ? height : 0, parent.width * media.progress)
            height: parent.height
            radius: 4
            color: "#c4c4c4"
            Behavior on width {
                NumberAnimation { duration: Theme.reducedMotion ? 0 : 250 }
            }
        }
        MouseArea {
            objectName: "media-seek"
            anchors.fill: parent
            anchors.margins: -6
            enabled: !!media.player?.canSeek && media.length > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: event => {
                media.player.position = Math.max(0, Math.min(1, (event.x - 6) / track.width)) * media.length;
            }
        }
    }
    Label {
        objectName: "media-length"
        x: parent.width - 50
        y: 252
        width: 42
        height: 20
        verticalAlignment: Text.AlignVCenter
        text: media.timecode(media.length)
        font.pixelSize: 11
    }
}
