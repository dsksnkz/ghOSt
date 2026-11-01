import assert from "node:assert/strict";
import {existsSync, readFileSync} from "node:fs";
import test from "node:test";

const read = name => readFileSync(new URL("../site/" + name, import.meta.url), "utf8");
const page = read("index.html");

test("every local image, script and stylesheet exists", () => {
  for (const [, path] of page.matchAll(/(?:src|href)="((?:assets\/)?[^"#:]+\.[a-z]+)"/g))
    assert.ok(existsSync(new URL("../site/" + path, import.meta.url)), path);
});

test("images reserve space and describe themselves", () => {
  for (const [tag] of page.matchAll(/<img\b[^>]*>/g)) {
    assert.match(tag, /width="\d+"/);
    assert.match(tag, /height="\d+"/);
    assert.match(tag, /alt="/);
  }
});

test("install commands match the installer", () => {
  assert.match(page, /git clone https:\/\/github\.com\/dsksnkz\/ghOSt\.git/);
  assert.match(page, /\.\/install\.sh --activate/);
  assert.match(page, /\.\/install\.sh --restore/);
  assert.match(readFileSync(new URL("../scripts/install.py", import.meta.url), "utf8"), /"--restore"/);
});

test("no removed font, no personal path, one primary action", () => {
  for (const name of ["index.html", "style.css", "icons.html", "icons.css"]) {
    const text = read(name);
    assert.doesNotMatch(text, /JetBrains|Turret|\/home\/matte/, name);
    assert.doesNotMatch(text, /[\u2013\u2014]/, name);
  }
  assert.equal(page.match(/button primary/g).length, 1);
});

test("motion stops for people who ask for less", () => {
  const style = read("style.css");
  assert.match(style, /prefers-reduced-motion: no-preference/);
  assert.match(style, /prefers-reduced-motion: reduce/);
});
