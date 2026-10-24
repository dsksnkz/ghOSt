const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const layout = {};
vm.createContext(layout);
vm.runInContext(fs.readFileSync("config/quickshell/ghost-bar/RailLayout.js", "utf8"), layout);
const defaults = layout.defaults();
assert.equal(defaults.length, 8);
assert.equal(defaults.filter(item => item.zone === "center")[0].id, "clock");
const moved = layout.move(defaults, 0, 1);
assert.equal(moved[0].id, "workspaces");
assert.equal(defaults[0].id, "menu");
assert.equal(layout.neighbour(defaults, 3, 1), -1);
const hidden = layout.place(defaults, "clock", "hidden", "", false);
assert.equal(hidden.find(entry => entry.id === "clock").zone, "hidden");
const afterNetwork = layout.place(hidden, "network", "right", "bluetooth", true);
assert.ok(afterNetwork.findIndex(entry => entry.id === "network") > afterNetwork.findIndex(entry => entry.id === "bluetooth"));
const leftClock = layout.place(afterNetwork, "clock", "left", "menu", false);
assert.equal(leftClock[0].id, "clock");
assert.equal(new Set(leftClock.map(entry => entry.id)).size, 8);
for (let seed = 0; seed < 150; seed++) {
  let state = seed + 1;
  const entries = defaults.map(entry => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    return {id: entry.id, zone: layout.zones[(state >>> 16) % 4]};
  });
  for (const width of [1882, 2112]) {
    const positions = layout.geometry(entries, width);
    const visible = entries.filter(entry => entry.zone !== "hidden").map(entry => ({
      x: positions[entry.id].x,
      width: layout.items.find(item => item.id === entry.id).width,
    })).sort((a, b) => a.x - b.x);
    for (let index = 0; index < visible.length; index++) {
      assert.ok(visible[index].x >= 0);
      assert.ok(visible[index].x + visible[index].width <= width);
      if (index) assert.ok(visible[index].x >= visible[index - 1].x + visible[index - 1].width);
    }
    for (const entry of entries) assert.equal(positions[entry.id].visible, entry.zone !== "hidden");
  }
}
console.log("PASS: top-bar catalogue, immutable reorder, zones, hiding and bounded non-overlapping layout");
