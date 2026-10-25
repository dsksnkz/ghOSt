// Move the launcher and media windows themselves, retaining their full
// dimensions and input area: they slide down from behind the rail.
function duration(page, reducedMotion, standardDuration) {
    return reducedMotion ? 0 : page === "launcher" ? 150 : standardDuration;
}

function topMargin(page, reveal, height) {
    if (page === "launcher" || page === "media")
        return 68 - Math.round((height + 68) * (1 - reveal));
    return page === "calendar" ? 82 : 68;
}
