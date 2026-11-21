const assert = require('node:assert/strict');
const { shouldScan } = require('../config/quickshell/ghost-bar/NetworkScanPolicy.js');

const idle = {
    wifiAvailable: true,
    wifiEnabled: true,
    panel: '',
    networkSettingsVisible: false,
};

assert.equal(shouldScan(idle), false, 'Closed browsers must not keep scanning');
assert.equal(shouldScan({ ...idle, networkSettingsVisible: true }), true);
assert.equal(shouldScan({ ...idle, panel: 'network' }), true);
assert.equal(shouldScan({ ...idle, panel: 'calendar' }), false);

// Exhaust all boolean combinations, including missing devices.
let cases = 0;
for (const wifiAvailable of [false, true]) {
    for (const wifiEnabled of [false, true]) {
        for (const networkSettingsVisible of [false, true]) {
            for (const panel of ['', 'calendar', 'network', 'audio']) {
                const state = { wifiAvailable, wifiEnabled, panel, networkSettingsVisible };
                const visibleBrowser = panel === 'network' || networkSettingsVisible;
                assert.equal(shouldScan(state), wifiAvailable && wifiEnabled && visibleBrowser);
                cases++;
            }
        }
    }
}

assert.equal(shouldScan(idle), false, 'Policy must not retain demand after a previous open state');
console.log(`PASS: ${cases} network visibility/device combinations and scanner release`);
