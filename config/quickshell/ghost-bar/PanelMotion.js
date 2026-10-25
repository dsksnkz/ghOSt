// Launcher and media keep a still window under the rail and slide only their
// content, so the compositor never repositions the surface mid-animation.
var railGap = 68;

function duration(page, reducedMotion, standardDuration) {
    return reducedMotion ? 0 : page === "launcher" ? 150 : standardDuration;
}

function topMargin(page, reveal, height) {
    if (page === "launcher" || page === "media")
        return 0;
    return page === "calendar" ? 82 : railGap;
}

// Extra window height above the content for pages that slide inside the window.
function windowLead(page) {
    return page === "launcher" || page === "media" ? railGap : 0;
}

// Fractional content offset inside the still window: hidden above at 0, resting at 1.
function slideOffset(page, reveal, height) {
    if (page !== "launcher" && page !== "media")
        return 0;
    return -(height + railGap) * (1 - reveal);
}
