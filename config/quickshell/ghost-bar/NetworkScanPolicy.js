// Scan only while an enabled Wi-Fi device has a visible network browser.
function shouldScan(state) {
    if (!state.wifiAvailable || !state.wifiEnabled)
        return false;

    return state.panel === "network"
        || (state.sidebarOpen && state.sidebarNetworkEnabled)
        || state.networkSettingsVisible;
}

if (typeof module !== "undefined")
    module.exports = { shouldScan };
