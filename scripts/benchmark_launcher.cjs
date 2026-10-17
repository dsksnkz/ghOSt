// Compare saved pre-change ranking with cached-catalogue searches, without UI
// or app execution: node scripts/benchmark_launcher.cjs <baseline LauncherSearch.js>
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const {performance} = require('node:perf_hooks');

if (!process.argv[2]) throw new Error('Supply a saved baseline LauncherSearch.js');
function load(path) {
    const context = vm.createContext({});
    vm.runInContext(fs.readFileSync(path, 'utf8'), context);
    return context;
}
const before = load(process.argv[2]);
const after = load('config/quickshell/ghost-bar/LauncherSearch.js');
const entries = Array.from({length: 2000}, (_, i) => ({
    id: 'app-' + i,
    name: ['Editor', 'Browser', 'Terminal', 'Music'][i % 4] + ' ' + i,
    genericName: 'Application ' + i,
    keywords: ['desktop', i % 2 ? 'web' : 'tools'],
    noDisplay: i % 41 === 0
}));
const pins = entries.filter((_, i) => i % 5 === 0).map(entry => entry.id);
const catalogue = after.prepare(entries);
const queries = ['', 'editor', 'web', 'music 12', 'unknown', 'desktop', 'browser', 'tools 4'];
for (const query of queries) {
    assert.deepEqual(Array.from(before.ranked(entries, query, pins), entry => entry.id),
        Array.from(after.rankedPrepared(catalogue, query, pins), entry => entry.id));
}
function medianSearchTime(search) {
    const times = [];
    for (let trial = 0; trial < 5; trial++) {
        const start = performance.now();
        for (let i = 0; i < 64; i++) search(queries[i % queries.length]);
        times.push(performance.now() - start);
    }
    return times.sort((a, b) => a - b)[2];
}
const oldMs = medianSearchTime(query => before.ranked(entries, query, pins));
const newMs = medianSearchTime(query => after.rankedPrepared(catalogue, query, pins));
console.log(JSON.stringify({entries: entries.length, pins: pins.length, queriesPerTrial: 64,
    trials: 5, equivalence: 'passed', medianBeforeMs: +oldMs.toFixed(2),
    medianAfterMs: +newMs.toFixed(2), speedup: +(oldMs / newMs).toFixed(2)}));
