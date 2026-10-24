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
  assert.ok(height <= 280 && height <= screen * .4 + 1);
  assert.ok(top >= screen * .29 && top + height < screen * .71 + 1);
  assert.ok(Math.abs(top + height / 2 - screen / 2) <= .5);
}
assert.equal(edge.step(99, 120), 100);
assert.equal(edge.step(1, -120), 0);
assert.equal(edge.step(50, 0), 50);
console.log('PASS: searchable Intro, recommendations, edge dead zones and bounded volume steps');
