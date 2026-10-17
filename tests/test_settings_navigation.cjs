const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const navigation = vm.createContext({});
vm.runInContext(fs.readFileSync('config/quickshell/ghost-bar/SettingsNavigation.js', 'utf8'), navigation);
const categories = navigation.categories();
const groups = navigation.groups();
const metrics = {rowHeight: 44, rowGap: 8, inset: 0, groupGap: 16};
const grouped = groups.map(group => group.map(id => categories.find(category => category.id === id)));
const layout = navigation.layout(grouped, metrics);

assert.equal(categories.length, 14);
assert.equal(new Set(categories.map(category => category.id)).size, 14);
assert.equal(groups[0].join(','), 'network,bluetooth,general,airplane,accessibility');
assert.equal(layout.rows.length, 14);
assert.equal(layout.groups.length, 4);
assert.equal(layout.height, 744);
assert.equal(layout.rows.find(row => row.id === 'general').y, 104);
assert.equal(layout.rows.find(row => row.id === 'sound').y, 268);
assert.equal(layout.rows.find(row => row.id === 'about').y, 700);
assert.equal(navigation.groupHeight(3, metrics), 148);
assert.equal(navigation.layout([], metrics).height, 0);

const single = navigation.layout([[categories.find(category => category.id === 'battery')]], metrics);
assert.equal(single.rows[0].y, 0);
assert.equal(single.height, 44);
const insetLayout = navigation.layout([[categories[0], categories[1]]], {...metrics, inset: 4});
assert.equal(insetLayout.rows[0].y, 4);
assert.equal(insetLayout.rows[1].y, 56);
assert.equal(insetLayout.height, 104);
assert.notEqual(layout.rows[0], categories[0], 'Layout must not mutate shared category data');
assert.equal(categories[0].y, undefined);
console.log('PASS: Settings category coverage, preserved order, exact geometry, filtering and immutable data');
