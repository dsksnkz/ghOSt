// Shared catalogue and pure layout operations; no service or preference writes.
var items = [
    {id: "workspaces", name: "Workspaces", zone: "left", width: 99},
    {id: "music", name: "Music", zone: "left", width: 220},
    {id: "clock", name: "Clock", zone: "center", width: 124},
    {id: "network", name: "Network", zone: "right", width: 28},
    {id: "bluetooth", name: "Bluetooth", zone: "right", width: 28},
    {id: "volume", name: "Volume", zone: "right", width: 28},
    {id: "battery", name: "Battery", zone: "right", width: 40},
    {id: "power", name: "Power", zone: "right", width: 38}
];
var zones = ["left", "center", "right", "hidden"];

function defaults() {
    return items.map(item => ({id: item.id, zone: item.zone}));
}

function neighbour(layout, index, step) {
    for (var next = index + step; next >= 0 && next < layout.length; next += step) {
        if (layout[next].zone === layout[index].zone)
            return next;
    }
    return -1;
}

function move(layout, index, step) {
    var copy = layout.slice();
    var next = neighbour(copy, index, step);
    if (next >= 0) {
        var entry = copy[index];
        copy[index] = copy[next];
        copy[next] = entry;
    }
    return copy;
}

function place(layout, id, zone, target, after) {
    if (id === target || !zones.includes(zone))
        return layout.slice();
    var moving = layout.find(entry => entry.id === id);
    if (!moving)
        return layout.slice();
    var copy = layout.filter(entry => entry.id !== id);
    var index = target ? copy.findIndex(entry => entry.id === target) : -1;
    if (index >= 0)
        index += after ? 1 : 0;
    else {
        index = copy.length;
        for (var i = copy.length - 1; i >= 0; --i) {
            if (copy[i].zone === zone) {
                index = i + 1;
                break;
            }
        }
    }
    copy.splice(index, 0, {id: id, zone: zone});
    return copy;
}

var statusIds = ["network", "bluetooth", "volume", "battery"];

// Status icons sit close together; every other neighbour keeps the wider gap.
function spacing(a, b) {
    return statusIds.includes(a.id) && statusIds.includes(b.id) ? 4 : 12;
}

function geometry(layout, width) {
    layout = layout.filter(entry => items.some(item => item.id === entry.id));
    var gap = 12, inset = 19, result = {}, groups = {}, sizes = {};
    for (var zone of zones.slice(0, 3)) {
        groups[zone] = layout.filter(entry => entry.zone === zone);
        sizes[zone] = groups[zone].reduce((sum, entry) => sum + items.find(item => item.id === entry.id).width, 0)
            + groups[zone].slice(1).reduce((sum, entry, index) => sum + spacing(groups[zone][index], entry), 0);
    }
    var center = (width - sizes.center) / 2;
    // Keep the middle group centered unless a large side group needs room.
    var minimum = groups.left.length ? inset + sizes.left + gap : inset;
    var maximum = width - inset - sizes.right - sizes.center - (groups.right.length ? gap : 0);
    center = Math.max(minimum, Math.min(maximum, center));
    var starts = {left: inset, center: center, right: width - inset - sizes.right};
    for (var group of zones.slice(0, 3)) {
        var x = starts[group];
        for (var entry of groups[group]) {
            result[entry.id] = {x: x, visible: true};
            x += items.find(item => item.id === entry.id).width;
            var next = groups[group][groups[group].indexOf(entry) + 1];
            if (next)
                x += spacing(entry, next);
        }
    }
    for (var entry of layout.filter(entry => entry.zone === "hidden"))
        result[entry.id] = {x: 0, visible: false};
    return result;
}
