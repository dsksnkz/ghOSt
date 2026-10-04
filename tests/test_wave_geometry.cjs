const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../config/quickshell/ghost-bar/WaveGeometry.js'), 'utf8').replace(/^\.pragma library\s*/, '');
const wave = vm.createContext({Math});
vm.runInContext(source, wave);
assert.equal(wave.samples(0, 2).length, 0);
assert.equal(wave.samples(123, 0).length, 0);
let checked = 0;
for (const width of [1, 64, 123, 144, 200]) {
    const points = wave.samples(width, 2);
    for (let phase = 0; phase < 6.3; phase += .07) {
        const vertices = [];
        const context = {
            beginPath() {}, moveTo() {}, closePath() {},
            lineTo(x, y) {vertices.push([x, y]);}
        };
        wave.trace(context, points, phase, 62, 5, width, 123);
        for (let i = 0; i < points.length; i++) {
            const x = points[i][0];
            assert.ok(Math.abs(vertices[i][1] - (62 + Math.sin(x / width * 6.28 + phase) * 5)) < 1e-12);
            checked++;
        }
        assert.equal(vertices.at(-1)[0], width);
        assert.equal(vertices.at(-1)[1], 123);
    }
}
console.log(`PASS: ${checked} cached wave vertices match original geometry`);
