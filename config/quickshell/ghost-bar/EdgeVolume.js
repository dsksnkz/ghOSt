// Full-height narrow edge regions; no desktop or service access here.
function bounds(screenHeight) {
    return {height: Math.max(0, Math.round(screenHeight)), top: 0};
}
function step(volume, delta) {
    return Math.max(0, Math.min(100, volume + (delta > 0 ? 2 : delta < 0 ? -2 : 0)));
}
function osdTop(screenHeight, popupHeight, pointerY) {
    var center = Number.isFinite(pointerY) && pointerY >= 0 ? pointerY : screenHeight / 2;
    return Math.max(0, Math.min(Math.max(0, screenHeight - popupHeight),
        Math.round(center - popupHeight / 2)));
}
