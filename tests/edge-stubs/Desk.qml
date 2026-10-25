pragma Singleton
import QtQuick
QtObject {
    property int volume: 30
    property bool muted: false
    property var audio: ({})
    function setVolume(value) { volume = Math.round(value * 100); }
}
