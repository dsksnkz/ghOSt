pragma Singleton
import QtQuick

QtObject {
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property color base: "#080808"
    readonly property color surface: "#101010"
    readonly property color raised: "#181818"
    readonly property color line: "#343434"
    readonly property color text: "#f4f4f4"
    readonly property color muted: "#a4a4a4"
    readonly property color faint: "#5d5d5d"
    // Compatibility names remain grayscale so older components cannot reintroduce color.
    readonly property color orange: text
    readonly property color cream: text
    readonly property color blue: text
    readonly property int fast: 90
    readonly property int motion: 150
    readonly property int panel: 220
}
