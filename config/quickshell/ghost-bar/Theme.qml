pragma Singleton
import QtQuick

QtObject {
    property bool reducedMotion: false
    // The Scale chosen in Settings; it multiplies every shell surface.
    property real shellScale: 1
    // Surfaces keep the same share of any display: 1 on a 1920 × 1080 output.
    function scaleFor(screen) {
        const width = screen?.width || 1920, height = screen?.height || 1080;
        return Math.min(width / 1920, height / 1080) * shellScale;
    }
    readonly property real outerRadius: 7
    // Compact height and uniformly scale contents; preserve the frame's width.
    readonly property real railHeight: 35
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
    // Wi-Fi, Bluetooth and battery menus share one spacing scale, by element class.
    readonly property int menuWidth: 430
    readonly property int menuEdge: 32          // Left and right margin of every row.
    readonly property int menuTop: 30           // Header icon and title top.
    readonly property int menuTextX: 82         // Header title and row names.
    readonly property int menuRule: 100         // Header rule, or the battery level bar.
    readonly property int menuSection: 24       // Between sections.
    readonly property int menuGap: 12           // Between items in a section; heading to content.
    readonly property int menuTight: 4          // Label to its value.
    readonly property int menuRow: 48           // Network and device rows.
    readonly property int menuButton: 32        // Button height.
    readonly property int menuInner: menuWidth - 2 * menuEdge
    readonly property int menuHeading: 14       // Section heading size.
    readonly property color menuHeadingInk: "#8a8a8a"
    readonly property int fast: 90
    readonly property int motion: 150
    readonly property int panel: 220

    function calendarWidth(screenWidth, screenHeight) {
        const desired = calendarPlaneWidth * scaleFor({width: screenWidth, height: screenHeight}) * calendarScale;
        const heightLimit = Math.max(1, screenHeight - 100) * calendarPlaneWidth / calendarPlaneHeight;
        return Math.floor(Math.min(desired, screenWidth - 32, heightLimit));
    }

    function innerRadius(padding) {
        return Math.max(0, outerRadius - padding);
    }
}
