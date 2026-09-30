const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync('config/quickshell/ghost-bar/LauncherSearch.js', 'utf8'), context);
const entries = [
  {id:'web', name:'Web', genericName:'Browser', keywords:['Internet']},
  {id:'kitty', name:'Kitty', genericName:'Terminal', categories:['TerminalEmulator']},
  {id:'tools', name:'Kitty tools', genericName:'Utilities'},
  {id:'hidden', name:'Kitty hidden', noDisplay:true},
];
const ids = (q, pins=[]) => Array.from(context.ranked(entries,q,pins), e=>e.id);
assert.deepEqual(ids('kitty'), ['kitty','tools']);
assert.deepEqual(ids('terminal'), ['kitty']);
assert.deepEqual(ids(' internet  '), ['web']);
assert.deepEqual(ids('kitty terminal'), ['kitty']);
assert.deepEqual(ids('kitty browser'), []);
assert.deepEqual(ids(''), ['kitty','tools','web']);
assert.deepEqual(ids('', ['web']), ['web','kitty','tools']);
assert.deepEqual(ids('kitty', ['tools']), ['kitty','tools']);
assert.deepEqual(ids('missing'), []);
assert.equal(context.iconFor(entries[1]), 'terminal');
for (const bad of ['{', 'null', '42', '{}']) assert.equal(context.readPins(bad).length, 0);
assert.deepEqual(Array.from(context.readPins('["web",3,"web","kitty"]')), ['web','kitty']);
console.log('Launcher: 15 ranking, filtering, icon and preference checks passed');
