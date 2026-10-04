import QtQuick

Canvas {
    id: image
    property url source
    property real radius: 0
    Image { id:picture;visible:false;source:image.source;onStatusChanged:if(status===Image.Ready)image.requestPaint() }
    onSourceChanged: { if(source.toString())loadImage(source);requestPaint(); }
    onImageLoaded: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onRadiusChanged: requestPaint()
    Component.onCompleted: if(source.toString())loadImage(source)
    onPaint: {
        const c=getContext("2d"),r=Math.max(0,Math.min(radius,width/2,height/2));
        c.reset();c.clearRect(0,0,width,height);
        if(!isImageLoaded(source))return;
        c.beginPath();c.moveTo(r,0);c.lineTo(width-r,0);
        c.bezierCurveTo(width,0,width,0,width,r);c.lineTo(width,height-r);
        c.bezierCurveTo(width,height,width,height,width-r,height);c.lineTo(r,height);
        c.bezierCurveTo(0,height,0,height,0,height-r);c.lineTo(0,r);
        c.bezierCurveTo(0,0,0,0,r,0);c.closePath();c.clip();
        // PreserveAspectCrop, matching Figma's FILL image transform.
        const iw=picture.sourceSize.width,ih=picture.sourceSize.height;
        if(!iw||!ih)return;
        const scale=Math.max(width/iw,height/ih),sw=width/scale,sh=height/scale;
        c.drawImage(source,(iw-sw)/2,(ih-sh)/2,sw,sh,0,0,width,height);
    }
}
