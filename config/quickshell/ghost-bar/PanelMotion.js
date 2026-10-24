// Move the launcher window itself, retaining its full dimensions and input area.
function duration(page, reducedMotion, standardDuration) {
    return reducedMotion ? 0 : page === "launcher" ? 150 : standardDuration;
}

function topMargin(page, reveal, height) {
    if (page === "launcher")
        return 68 - Math.round((height + 68) * (1 - reveal));
    return page === "calendar" ? 82 : 68;
}
