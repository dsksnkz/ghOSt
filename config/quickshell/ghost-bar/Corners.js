.pragma library

// Radius and smoothing are separate Figma measurements. The previous single
// cubic used the rectangle vertex twice, making a 15px corner look nearly square.
// Parameter equations adapted from figma-squircle (MIT), Tien Pham, 2021.
// See docs/licenses/figma-squircle.txt and docs/changes/2026-10-04-corners.md.
function geometry(width, height, radius, smoothing) {
    const budget = Math.max(0, Math.min(width, height) / 2);
    const r = Math.max(0, Math.min(radius, budget));
    const s = r ? Math.max(0, Math.min(smoothing, 1, budget / r - 1)) : 0;
    const p = r * (1 + s), beta = Math.PI * s / 4;
    const length = Math.sin(Math.PI * (1 - s) / 4) * r * Math.SQRT2;
    const c = r * Math.tan(beta / 2) * Math.cos(beta), d = c * Math.tan(beta);
    const b = (p - length - c - d) / 3, a = 2 * b;
    const k = 4 / 3 * Math.tan(Math.PI * (1 - s) / 8);
    const local = [
        [-p + a, 0, -p + a + b, 0, -length - d, d],
        [-length-d+k*r*Math.cos(beta), d+k*r*Math.sin(beta),
         -d-k*r*Math.sin(beta), d+length-k*r*Math.cos(beta), -d, d+length],
        [0, d+length+c, 0, d+length+b+c, 0, p]
    ];
    const origins = [[width,0],[width,height],[0,height],[0,0]];
    function point(x,y,turn) {
        const o = origins[turn];
        if (turn === 1) return [o[0]-y,o[1]+x];
        if (turn === 2) return [o[0]-x,o[1]-y];
        if (turn === 3) return [o[0]+y,o[1]-x];
        return [o[0]+x,o[1]+y];
    }
    const commands = [['M',width-p,0]];
    for (let turn=0;turn<4;turn++) {
        if (turn) commands.push(['L'].concat(point(-p,0,turn)));
        for (const curve of local) {
            let values=['C'];
            for(let i=0;i<6;i+=2) values=values.concat(point(curve[i],curve[i+1],turn));
            commands.push(values);
        }
    }
    commands.push(['Z']);
    return {radius:r,smoothing:s,reach:p,commands:commands};
}
function svg(width,height,radius,smoothing) {
    return geometry(width,height,radius,smoothing).commands.map(c=>c.join(' ')).join(' ');
}
function trace(context,width,height,radius,smoothing) {
    traceCommands(context, geometry(width,height,radius,smoothing).commands);
}
// Animated canvases keep immutable geometry, instead of rebuilding corner
// equations and temporary arrays on every frame.
function traceCommands(context,commands) {
    context.beginPath();
    for(const c of commands) {
        if(c[0]==='M') context.moveTo(c[1],c[2]);
        else if(c[0]==='L') context.lineTo(c[1],c[2]);
        else if(c[0]==='C') context.bezierCurveTo(c[1],c[2],c[3],c[4],c[5],c[6]);
        else context.closePath();
    }
}
