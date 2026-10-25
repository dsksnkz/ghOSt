import QtQuick

// Popup opened from the rail's audio element: artwork, track, seek and transport.
Item {
    id: media
    property bool active: false
    property string soundGroup: "rail"
    readonly property var player: Desk.player
    readonly property bool playing: Desk.playing
    readonly property real length: player?.length > 0 ? player.length : 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, (player?.position ?? 0) / length)) : 0
    readonly property bool hasArt: art.status === Image.Ready
    implicitHeight: 262

    function timecode(seconds) {
        return Math.floor(Math.max(0, seconds) / 60) + ":" + String(Math.floor(Math.max(0, seconds) % 60)).padStart(2, "0");
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
        active: media.active && media.playing && !media.hasArt && !Theme.reducedMotion
    }
    Timer {
        interval: 1000
        repeat: true
        running: media.active && media.playing && !!media.player?.positionSupported
        onTriggered: media.player.positionChanged()
    }

    // Header
    Label {
        x: 20
        y: 18
        text: media.player?.identity ? "Now playing · " + media.player.identity : "Now playing"
        width: parent.width - 80
        font.pixelSize: 12
        color: Theme.muted
    }
    Key {
        objectName: "media-close"
        x: parent.width - 48
        y: 12
        width: 28
        height: 28
        radius: 7
        color: "#151515"
        hint: "Close"
        onClicked: Desk.close()
        SvgIcon {
            anchors.centerIn: parent
            width: 14
            height: 14
            name: "close"
        }
    }

    // Artwork, or live spectrum bars when the player provides none.
    G2Surface {
        id: artFrame
        x: 20
        y: 52
        width: 76
        height: 76
        radius: 7
        color: "#151515"
        clip: true
        Image {
            id: art
            anchors.fill: parent
            source: media.player?.trackArtUrl || ""
            sourceSize.width: 152
            sourceSize.height: 152
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: media.hasArt
        }
        Row {
            visible: !media.hasArt
            anchors.centerIn: parent
            spacing: 3
            Repeater {
                model: [1, 3, 5, 7, 9, 11, 13]
                Item {
                    required property int modelData
                    width: 3
                    height: 30
                    G2Surface {
                        objectName: "media-spectrum-bar"
                        anchors.bottom: parent.bottom
                        width: 3
                        height: media.playing ? Math.max(4, 30 * spectrum.levels[parent.modelData]) : 4
                        radius: 1.5
                        color: media.playing ? Theme.text : Theme.faint
                        Behavior on height {
                            NumberAnimation { duration: Theme.reducedMotion ? 0 : 65 }
                        }
                    }
                }
            }
        }
    }
    Column {
        x: 112
        y: 56
        width: parent.width - 132
        spacing: 4
        Label {
            id: title
            objectName: "media-title"
            width: parent.width
            text: media.player?.trackTitle || "Nothing playing"
            font.pixelSize: 17
            font.weight: media.player ? Theme.mediumWeight : Font.Normal
            color: media.player ? Theme.text : Theme.muted
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: media.player?.trackArtist || ""
            font.pixelSize: 12
            color: Theme.muted
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: media.player?.trackAlbum || ""
            font.pixelSize: 11
            color: Theme.faint
        }
    }

    // Seek bar with mono timecodes.
    Item {
        id: seek
        x: 20
        y: 148
        width: parent.width - 40
        height: 30
        readonly property bool enabledSeek: !!media.player?.canSeek && media.length > 0
        Rectangle {
            id: track
            y: 6
            width: parent.width
            height: 4
            radius: 2
            color: "#1d1d1d"
            Rectangle {
                width: Math.max(media.progress > 0 ? height : 0, parent.width * media.progress)
                height: parent.height
                radius: 2
                color: Theme.text
                Behavior on width {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : 250 }
                }
            }
            Rectangle {
                x: parent.width * media.progress - width / 2
                y: (parent.height - height) / 2
                width: 12
                height: 12
                radius: 6
                color: Theme.text
                visible: seek.enabledSeek
                opacity: seekArea.containsMouse || seekArea.pressed ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.fast }
                }
            }
        }
        Text {
            y: 16
            text: media.timecode(media.player?.position ?? 0)
            font.family: Theme.jetRegular.name
            font.pixelSize: 10
            color: Theme.muted
        }
        Text {
            anchors.right: parent.right
            y: 16
            text: media.timecode(media.length)
            font.family: Theme.jetRegular.name
            font.pixelSize: 10
            color: Theme.muted
        }
        MouseArea {
            id: seekArea
            y: -4
            width: parent.width
            height: 20
            hoverEnabled: true
            enabled: seek.enabledSeek
            cursorShape: Qt.PointingHandCursor
            onClicked: event => {
                UiSounds.play("rail");
                media.player.position = Math.max(0, Math.min(1, event.x / width)) * media.length;
            }
        }
    }

    // Transport: 10 s seek either side of previous / play / next.
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 192
        spacing: 14
        Key {
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 32
            radius: 7
            hint: "Seek back"
            enabled: !!media.player?.canSeek
            onClicked: media.player.seek(-10)
            Text {
                anchors.centerIn: parent
                text: "−10"
                font.family: Theme.jetRegular.name
                font.pixelSize: 11
                color: Theme.muted
            }
        }
        Repeater {
            model: ["previous", media.playing ? "pause" : "play", "next"]
            Key {
                id: transport
                required property string modelData
                required property int index
                readonly property bool primary: index === 1
                anchors.verticalCenter: parent.verticalCenter
                width: primary ? 48 : 36
                height: primary ? 48 : 36
                radius: primary ? 24 : 18
                color: primary && media.player ? Theme.text : "transparent"
                hint: modelData
                enabled: index === 0 ? !!media.player?.canGoPrevious : index === 2 ? !!media.player?.canGoNext : !!media.player?.canTogglePlaying
                onClicked: index === 0 ? media.player.previous() : index === 2 ? media.player.next() : media.player.togglePlaying()
                SvgIcon {
                    anchors.centerIn: parent
                    width: transport.primary ? 22 : 18
                    height: transport.primary ? 22 : 18
                    name: transport.modelData
                    black: transport.primary && !!media.player
                }
            }
        }
        Key {
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 32
            radius: 7
            hint: "Seek forward"
            enabled: !!media.player?.canSeek
            onClicked: media.player.seek(10)
            Text {
                anchors.centerIn: parent
                text: "+10"
                font.family: Theme.jetRegular.name
                font.pixelSize: 11
                color: Theme.muted
            }
        }
    }
}
