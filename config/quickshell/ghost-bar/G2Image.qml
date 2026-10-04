import QtQuick
import "Corners.js" as Corners

Canvas {
    id: image
    property url source
    property real radius: 0
    property real smoothing: .6
    Image { id:picture;visible:false;source:image.source;onStatusChanged:if(status===Image.Ready)image.requestPaint() }
    onSourceChanged: { if(source.toString())loadImage(source);requestPaint(); }
    onImageLoaded: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onSmoothingChanged: requestPaint()
    Component.onCompleted: if(source.toString())loadImage(source)
    onPaint: {
        const c=getContext("2d"),r=Math.max(0,Math.min(radius,width/2,height/2));
        c.reset();c.clearRect(0,0,width,height);
        if(!isImageLoaded(source))return;
        Corners.trace(c,width,height,r,smoothing);c.clip();
        // PreserveAspectCrop, matching Figma's FILL image transform.
        const iw=picture.sourceSize.width,ih=picture.sourceSize.height;
        if(!iw||!ih)return;
        const scale=Math.max(width/iw,height/ih),sw=width/scale,sh=height/scale;
        c.drawImage(source,(iw-sw)/2,(ih-sh)/2,sw,sh,0,0,width,height);
    }
}
