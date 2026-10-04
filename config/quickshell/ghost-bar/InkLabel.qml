import QtQuick

// Center visible glyph ink, not the font's asymmetric ascent/descent box.
Label {
    id: label
    readonly property rect inkBounds: metrics.tightBoundingRect(text)
    readonly property real inkCenterY: baselineOffset + inkBounds.y + inkBounds.height / 2
    FontMetrics {
        id: metrics
        font: label.font
    }
    transform: Translate {
        y: label.height / 2 - label.inkCenterY
    }
}
