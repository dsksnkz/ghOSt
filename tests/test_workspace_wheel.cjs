const assert = require('node:assert/strict');
const geometry = require('../config/quickshell/ghost-bar/WorkspaceWheel.js');
assert.deepEqual(geometry.ring([],1), [1,2,3,4,5]);
assert.deepEqual(geometry.ring([{id:8,windows:1},{id:6,windows:0},{id:-4,windows:1}],1),[1,2,3,4,5,8]);
assert.deepEqual(geometry.ring([],7),[1,2,3,4,5,7]);
assert.equal(geometry.distance(4,0,5,0),1);
assert.equal(geometry.distance(0,4,5,0),-1);
assert.equal(geometry.distance(0,3,5,1),3);
assert.equal(geometry.distance(3,0,5,-1),-3);
assert.equal(geometry.modulo(-1,5),4);
for (const [offset,x,y,scale] of [[-1,0,16,11/15],[0,36,10,1],[1,76,16,11/15]]) {
    const actual=geometry.project(offset);
    assert.ok(Math.abs(actual.x-x)<1e-8);
    assert.ok(Math.abs(actual.y-y)<1e-8);
    assert.ok(Math.abs(actual.scale-scale)<1e-8);
    assert.equal(Math.abs(actual.rotation),0);
    assert.ok(Math.abs(actual.opacity-1)<1e-8);
}
for(let offset=-1.45;offset<=1.45;offset+=.01) {
    const actual=geometry.project(offset);
    assert.ok(actual.scale>0 && actual.scale<=1);
    assert.ok(actual.opacity>=0 && actual.opacity<=1);
}
assert.notEqual(geometry.project(.5).rotation,0);
assert.notEqual(geometry.project(.5).y,10);
console.log('PASS: workspace eligibility, directed wraparound, measured settled positions and bounded cylindrical projection');
