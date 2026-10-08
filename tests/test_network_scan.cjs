const assert = require('node:assert/strict');
const { shouldScan } = require('../config/quickshell/ghost-bar/NetworkScanPolicy.js');

const idle = {
    wifiAvailable: true,
    wifiEnabled: true,
    panel: '',
    sidebarOpen: false,
    sidebarNetworkEnabled: true,
    networkSettingsVisible: false,
};

assert.equal(shouldScan(idle), false, 'Closed browsers must not keep scanning');
assert.equal(shouldScan({ ...idle, sidebarOpen: true }), true);
assert.equal(shouldScan({ ...idle, networkSettingsVisible: true }), true);
assert.equal(shouldScan({ ...idle, panel: 'network' }), true);
assert.equal(shouldScan({ ...idle, sidebarOpen: true, sidebarNetworkEnabled: false }), false);
assert.equal(shouldScan({ ...idle, panel: 'calendar' }), false);

// Exhaust all boolean combinations, including hidden widgets/missing devices.
let cases = 0;
for (const wifiAvailable of [false, true]) {
    for (const wifiEnabled of [false, true]) {
        for (const sidebarOpen of [false, true]) {
            for (const sidebarNetworkEnabled of [false, true]) {
                for (const networkSettingsVisible of [false, true]) {
                    for (const panel of ['', 'calendar', 'network', 'audio']) {
                        const state = { wifiAvailable, wifiEnabled, panel,
                            sidebarOpen, sidebarNetworkEnabled, networkSettingsVisible };
                        const visibleBrowser = panel === 'network'
                            || (sidebarOpen && sidebarNetworkEnabled)
                            || networkSettingsVisible;
                        assert.equal(shouldScan(state), wifiAvailable && wifiEnabled && visibleBrowser);
                        cases++;
                    }
                }
            }
        }
    }
}

assert.equal(shouldScan(idle), false, 'Policy must not retain demand after a previous open state');
console.log(`PASS: ${cases} network visibility/device combinations and scanner release`);
