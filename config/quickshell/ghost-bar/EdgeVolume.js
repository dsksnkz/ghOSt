// Keep edge hit regions small and centered; no desktop or service access here.
function bounds(screenHeight) {
    var height = Math.min(280, Math.round(screenHeight * .4));
    return {height: height, top: Math.round((screenHeight - height) / 2)};
}
function step(volume, delta) {
    return Math.max(0, Math.min(100, volume + (delta > 0 ? 2 : delta < 0 ? -2 : 0)));
}
