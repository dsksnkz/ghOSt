pragma Singleton
import QtQuick

QtObject {
    property bool reducedMotion: false
    readonly property real outerRadius: 7
    // Compact height and uniformly scale contents; preserve the frame's width.
    readonly property real railVerticalScale: 0.9
    readonly property real railOuterGapScale: 0.5
    readonly property real railHeight: (46 + 18 * railOuterGapScale) * railVerticalScale
    // Reference coordinates stay fixed; the complete calendar scales together.
    readonly property real calendarScale: 1.12
    // Calendar design plane; the window keeps this aspect ratio at every size.
    readonly property real calendarPlaneWidth: 820
    readonly property real calendarPlaneHeight: 380
    // Reversible sans-serif trial. Original bundled faces remain available.
    readonly property string font: "Adwaita Sans"
    // Keep emphasis, with a modest 50-point reduction for the sans-serif trial.
    readonly property int mediumWeight: 450
    readonly property int demiWeight: 550
    readonly property int boldWeight: 650
    readonly property FontLoader jetRegular: FontLoader {
        source: "fonts/JetBrainsMono-Regular.ttf"
    }

    readonly property FontLoader jetLight: FontLoader {
        source: "fonts/JetBrainsMono-Light.ttf"
    }

    readonly property FontLoader jetMedium: FontLoader {
        source: "fonts/JetBrainsMono-Medium.ttf"
    }

    readonly property FontLoader jetBold: FontLoader {
        source: "fonts/JetBrainsMono-Bold.ttf"
    }

    readonly property string textFont: font
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

    function calendarWidth(screenWidth, screenHeight) {
        const desired = screenWidth * calendarPlaneWidth / 1920 * calendarScale;
        const heightLimit = Math.max(1, screenHeight - 100) * calendarPlaneWidth / calendarPlaneHeight;
        return Math.floor(Math.min(desired, screenWidth - 32, heightLimit));
    }

    function innerRadius(padding) {
        return Math.max(0, outerRadius - padding);
    }
}
