import QtQuick
import QtQuick.Shapes as Shapes

Item {
    id: surface
    property color color: "transparent"
    property real radius: 0
    property Gradient gradient: null
    component BorderStyle: QtObject { property color color: "transparent"; property real width: 0 }
    property BorderStyle border: BorderStyle {}
    property var paintStops: [0,1,color,color,false]
    function syncGradient() {
        const stops=gradient?.stops;
        paintStops=[stops?.[0]?.position ?? 0,stops?.[1]?.position ?? 1,stops?.[0]?.color ?? color,stops?.[1]?.color ?? color,gradient?.orientation===Gradient.Horizontal];
    }
    onGradientChanged: Qt.callLater(syncGradient)
    onColorChanged: syncGradient()
    Component.onCompleted: syncGradient()
    readonly property real inset: Math.max(0,border.width)/2
    readonly property real r: Math.max(0,Math.min(radius-inset,(width-2*inset)/2,(height-2*inset)/2))
    // Coincident corner controls give zero curvature at both straight joins.
    Shapes.Shape {
        anchors.fill: parent
        preferredRendererType: Shapes.Shape.CurveRenderer
        Shapes.ShapePath {
            strokeColor: surface.border.color
            strokeWidth: surface.border.width>0 ? surface.border.width : -1
            fillColor: surface.color
            fillGradient: surface.gradient ? shading : null
            startX: surface.inset+surface.r; startY: surface.inset
            PathLine { x:surface.width-surface.inset-surface.r; y:surface.inset }
            PathCubic { x:surface.width-surface.inset; y:surface.inset+surface.r; control1X:surface.width-surface.inset; control1Y:surface.inset; control2X:control1X; control2Y:control1Y }
            PathLine { x:surface.width-surface.inset; y:surface.height-surface.inset-surface.r }
            PathCubic { x:surface.width-surface.inset-surface.r; y:surface.height-surface.inset; control1X:surface.width-surface.inset; control1Y:surface.height-surface.inset; control2X:control1X; control2Y:control1Y }
            PathLine { x:surface.inset+surface.r; y:surface.height-surface.inset }
            PathCubic { x:surface.inset; y:surface.height-surface.inset-surface.r; control1X:surface.inset; control1Y:surface.height-surface.inset; control2X:control1X; control2Y:control1Y }
            PathLine { x:surface.inset; y:surface.inset+surface.r }
            PathCubic { x:surface.inset+surface.r; y:surface.inset; control1X:surface.inset; control1Y:surface.inset; control2X:control1X; control2Y:control1Y }
        }
    }
    Shapes.LinearGradient {
        id: shading
        x1:0; y1:0
        x2:surface.paintStops[4] ? surface.width : 0
        y2:surface.paintStops[4] ? 0 : surface.height
        GradientStop { position:surface.paintStops[0]; color:surface.paintStops[2] }
        GradientStop { position:surface.paintStops[1]; color:surface.paintStops[3] }
    }
}
