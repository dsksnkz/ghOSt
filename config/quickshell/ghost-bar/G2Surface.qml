import QtQuick
import QtQuick.Shapes as Shapes
import "Corners.js" as Corners

Item {
    id: surface
    property color color: "transparent"
    property real radius: 0
    property real smoothing: 0
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
    // Match Figma's radius AND smoothing, rather than substituting a squircle.
    Shapes.Shape {
        preferredRendererType: Shapes.Shape.CurveRenderer
        Shapes.ShapePath {
            strokeColor: surface.border.color
            strokeWidth: surface.border.width>0 ? surface.border.width : -1
            fillColor: surface.color
            fillGradient: surface.gradient ? shading : null
            PathSvg { path: Corners.svg(Math.max(0,surface.width-2*surface.inset),Math.max(0,surface.height-2*surface.inset),surface.r,surface.smoothing) }
        }
        x:surface.inset; y:surface.inset
        width:surface.width-2*surface.inset; height:surface.height-2*surface.inset
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
