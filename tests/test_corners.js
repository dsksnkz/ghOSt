const fs=require('fs'),vm=require('vm'),assert=require('assert');
const code=fs.readFileSync('config/quickshell/ghost-bar/Corners.js','utf8').replace('.pragma library','');
const context=vm.createContext({Math});vm.runInContext(code,context);
for(const [w,h,r,s] of [[144,222,15,0],[134,213,11,0],[116,116,21,.6],[63.95,63.95,21,.6],[231,215.2,10,0],[35,35,8,0],[24,24,15,0],[1920,46,7,0],[1,36,0,0]]) {
    const g=context.geometry(w,h,r,s);
    assert(g.radius<=Math.min(w,h)/2 && g.reach<=Math.min(w,h)/2);
    for(const c of g.commands)for(let i=1;i<c.length;i+=2){
        assert(Number.isFinite(c[i])&&Number.isFinite(c[i+1]));
        assert(c[i]>=-1e-8&&c[i]<=w+1e-8&&c[i+1]>=-1e-8&&c[i+1]<=h+1e-8);
    }
    assert.equal(g.commands.filter(c=>c[0]==='C').length,12);
    assert.equal(g.commands.at(-1)[0],'Z');
}
const circle=context.geometry(144,222,15,0), arc=circle.commands[2];
// Quarter-circle control offsets, rather than both controls at the vertex.
assert(Math.abs(arc[1]-(144-15+15*4/3*Math.tan(Math.PI/8)))<1e-8);
assert(Math.abs(arc[4]-(15-15*4/3*Math.tan(Math.PI/8)))<1e-8);
const smooth=context.geometry(116,116,21,.6);
assert(Math.abs(smooth.reach-33.6)<1e-8);
assert.equal(smooth.smoothing,.6);
assert(context.geometry(63.95,63.95,21,.6).smoothing<.6);
console.log('PASS: measured radii, circular geometry, 60% smoothing, bounded short controls and closed symmetric paths');
