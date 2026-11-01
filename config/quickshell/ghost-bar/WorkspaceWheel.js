// Deterministic cylindrical projection; the component owns input and animation.
function ring(workspaces, current) {
    var ids = [1, 2, 3, 4, 5];
    workspaces.forEach(function (w) {
        if (w.id > 5 && w.windows > 0 && ids.indexOf(w.id) < 0) ids.push(w.id);
    });
    // Show a manually opened higher empty desktop without adding a scroll target.
    if (current > 5 && ids.indexOf(current) < 0) ids.push(current);
    return ids.sort(function (a, b) { return a - b; });
}
function modulo(value, count) { return ((value % count) + count) % count; }
function distance(from, to, count, direction) {
    var delta = to - from;
    if (direction > 0) return modulo(delta, count);
    if (direction < 0) return -modulo(-delta, count);
    if (delta > count / 2) delta -= count;
    if (delta < -count / 2) delta += count;
    return delta;
}
function project(offset) {
    var a = Math.min(1.5, Math.abs(offset));
    var angle = a * Math.PI / 3;
    var depth = Math.cos(angle);
    // Settled label origins 0 / 38 / 76px: the centre digit sits between equal gaps.
    var radius = 38 / Math.sin(Math.PI / 3);
    return {
        x: 38 + (offset < 0 ? -1 : 1) * Math.sin(angle) * radius,
        // Scaled about the label's top edge; every digit keeps one centre line.
        y: 14 - 9 * (1 - (1 - depth) * (8 / 15)),
        scale: 1 - (1 - depth) * (8 / 15),
        rotation: -offset * Math.max(0, 1 - a) * 100,
        opacity: Math.max(0, Math.min(1, (1.45 - a) / .45)),
        depth: depth,
        ink: Math.round(184 + 71 * Math.max(0, depth * 2 - 1))
    };
}
if (typeof module !== 'undefined') module.exports = {ring, modulo, distance, project};
