import QtQuick

// Compatibility entry point: every surface uses the same owned SVG geometry.
SvgIcon {
    property color ink: Theme.text
    property real stroke: 2 // Retained API; vector weight is canonical, not per-use.

    implicitWidth: 18
    implicitHeight: 18
    name: "dot"
    black: ink.r + ink.g + ink.b < .4
    opacity: ink.a * (black ? 1 - Math.max(ink.r, ink.g, ink.b) : Math.max(ink.r, ink.g, ink.b))
}
