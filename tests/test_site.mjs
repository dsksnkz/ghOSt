import assert from "node:assert/strict";
import {existsSync} from "node:fs";
import test from "node:test";
import {views, settingsPages, settingsView, motionGroups} from "../site/catalogue.mjs";
import {revealOrder, entranceFrames, groupTiming} from "../site/motion.mjs";

test("only the seven requested views appear", () => {
  assert.deepEqual(Object.keys(views), [
    "rail", "calendar", "sidebar", "settings", "launcher", "sidebar-motion", "calendar-motion",
  ]);
});

test("every view and Settings page has an existing, bounded capture", () => {
  assert.equal(settingsPages.length, 14);
  const captures = [...Object.values(views), ...settingsPages.map((_, index) => settingsView(index))];
  for (const view of captures) {
    assert.ok(existsSync(new URL("../site/assets/" + view.file, import.meta.url)), view.file);
    const [left, top, width, height] = view.crop;
    assert.ok(left >= 0 && top >= 0 && width > 0 && height > 0);
    assert.ok(left + width <= view.size[0] && top + height <= view.size[1]);
  }
});

test("motion fragments fit their component", () => {
  for (const kind of ["sidebar", "calendar"]) {
    const view = views[kind + "-motion"];
    for (const [left, top, width, height] of motionGroups[kind]) {
      assert.ok(left >= 0 && top >= 0);
      assert.ok(left + width <= view.crop[2] && top + height <= view.crop[3]);
    }
  }
});

test("reveal includes each group once and never repeats the previous order", () => {
  const first = revealOrder(6, [], () => 0.5);
  const second = revealOrder(6, first, () => 0.5);
  assert.deepEqual([...first].sort(), [0, 1, 2, 3, 4, 5]);
  assert.deepEqual([...second].sort(), [0, 1, 2, 3, 4, 5]);
  assert.notDeepEqual(first, second);
});

test("entrance direction and total calendar duration follow the brief", () => {
  assert.match(entranceFrames("sidebar")[0].transform, /translateX\(-/);
  assert.match(entranceFrames("calendar")[0].transform, /translateY\(-/);
  const last = groupTiming("calendar", 5);
  assert.equal(last.delay + last.duration, 1460);
});
