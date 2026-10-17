// Settings navigation data and geometry only; no system actions or UI objects.
// IDs are stable routing keys. Category order and displayed group order differ
// deliberately: preserve both when adding or moving a page.
function categories() {
    return [
        {id: "network", name: "Wireless Network", icon: "wifi"},
        {id: "bluetooth", name: "Bluetooth", icon: "bluetooth"},
        {id: "general", name: "General", icon: "settings"},
        {id: "airplane", name: "Airplane Mode", icon: "network"},
        {id: "accessibility", name: "Accessibility", icon: "accessibility"},
        {id: "sound", name: "Sound", icon: "volume"},
        {id: "battery", name: "Battery", icon: "battery"},
        {id: "widgets", name: "Sidebar widgets", icon: "appearance"},
        {id: "brightness", name: "Brightness", icon: "brightness"},
        {id: "wallpaper", name: "Wallpaper", icon: "wallpaper"},
        {id: "notifications", name: "Notifications", icon: "notifications"},
        {id: "storage", name: "Storage", icon: "storage"},
        {id: "applications", name: "Applications", icon: "app"},
        {id: "about", name: "System information", icon: "info"}
    ];
}

function groups() {
    return [
        ["network", "bluetooth", "general", "airplane", "accessibility"],
        ["sound", "battery", "brightness"],
        ["widgets", "wallpaper", "notifications"],
        ["storage", "applications", "about"]
    ];
}

function groupHeight(count, metrics) {
    return count * metrics.rowHeight
        + Math.max(0, count - 1) * metrics.rowGap
        + 2 * metrics.inset;
}

function layout(categoryGroups, metrics) {
    const groupFrames = [];
    const rows = [];
    const stride = metrics.rowHeight + metrics.rowGap;
    let y = 0;

    for (const group of categoryGroups) {
        const height = groupHeight(group.length, metrics);
        groupFrames.push({y, height});
        group.forEach((category, index) => {
            rows.push(Object.assign({}, category, {
                y: y + metrics.inset + index * stride
            }));
        });
        y += height + metrics.groupGap;
    }

    return {
        groups: groupFrames,
        rows,
        height: Math.max(0, y - metrics.groupGap)
    };
}
