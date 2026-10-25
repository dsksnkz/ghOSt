const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
function load(name) {
  const context = {};
  vm.createContext(context);
  vm.runInContext(fs.readFileSync('config/quickshell/ghost-bar/' + name + '.js', 'utf8'), context);
  return context;
}
const intro = load('IntroTopics');
assert.equal(intro.search('').length, 7);
assert.equal(intro.search('ethernet')[0].id, 'connections');
assert.equal(intro.search('click sounds')[0].id, 'sound');
assert.equal(intro.search('zzzz missing').length, 0);
assert.equal(intro.topics.filter(t => t.recommended).length, 3);
const edge = load('EdgeVolume');
for (const screen of [600, 768, 1080, 1440, 2160]) {
  const {height, top} = edge.bounds(screen);
  assert.equal(height, screen);
  assert.equal(top, 0);
  for (const pointer of [0, 10, 50, screen / 2, screen - 50, screen - 1]) {
    const popupTop = edge.osdTop(screen, 310, pointer);
    assert.ok(popupTop >= 0 && popupTop + 310 <= screen);
    if (pointer >= 155 && pointer <= screen - 155)
      assert.ok(Math.abs(popupTop + 155 - pointer) <= .5);
  }
}
assert.equal(edge.step(99, 120), 100);
assert.equal(edge.step(1, -120), 0);
assert.equal(edge.step(50, 0), 50);
assert.equal(edge.osdTop(1080, 310, 440), 285);
assert.equal(edge.osdTop(1080, 310, 640), 485);
assert.equal(edge.osdTop(1080, 310, 0), 0);
assert.equal(edge.osdTop(1080, 310, 1080), 770);
assert.equal(edge.osdTop(1080, 310, -1), 385);
assert.equal(edge.osdTop(1080, 310, NaN), 385);
assert.equal(edge.osdTop(200, 310, 100), 0);
console.log('PASS: Intro search, full-height edges, pointer-aligned/clamped OSD and bounded volume');
