// Pure ranking logic, shared by QML and the Node regression tests.
function commandMode(query) {
    return /^\s*>/.test(query);
}

function commandEntry(query) {
    if (!commandMode(query)) return null;
    const command = query.replace(/^\s*>/, "").trim();
    if (!command) return null;
    return { id: "ghost-terminal-command", name: "Run: " + command,
        genericName: command, categories: ["TerminalEmulator"], terminalCommand: command };
}

function commandArgs(command) {
    // The entire user command is one shell argument, never concatenated into
    // a wrapper string. Pipes/quotes are interpreted only after explicit Run.
    return ["/bin/bash", "-lc", command];
}

function ranked(entries, query, pins) {
    return rankedPrepared(prepare(entries), query, pins);
}

// Normalize once when the desktop catalogue changes, not on every keystroke.
// Keep the original DesktopEntry for its native execute method and live icon.
function prepare(entries) {
    return entries.filter(entry => !entry.noDisplay && entry.name).map(entry => ({
        entry: entry,
        name: entry.name.toLocaleLowerCase(),
        extra: [entry.genericName || "", ...(entry.keywords || [])].join(" ").toLocaleLowerCase()
    }));
}

function rankedPrepared(catalogue, query, pins) {
    const words = query.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean);
    const pinned = new Set(pins);
    const hits = [];
    for (const record of catalogue) {
        const {entry, name, extra} = record;
        let score = 0;
        for (const word of words) {
            if (name === word) score += 100;
            else if (name.startsWith(word)) score += 60;
            else if (name.includes(word)) score += 30;
            else if (extra.includes(word)) score += 10;
            else { score = -1; break; }
        }
        if (score >= 0)
            hits.push({entry, score, pinned: pinned.has(entry.id)});
    }
    return hits.sort((a, b) =>
        b.score - a.score || Number(b.pinned) - Number(a.pinned) ||
        a.entry.name.localeCompare(b.entry.name) || a.entry.id.localeCompare(b.entry.id)
    ).map(hit => hit.entry);
}

function iconFor(entry) {
    const categories = entry.categories || [];
    if (categories.includes("TerminalEmulator")) return "terminal";
    if (categories.includes("WebBrowser")) return "browser";
    if (categories.includes("FileManager")) return "folder";
    if (categories.includes("Settings")) return "settings";
    return "app";
}

function readPins(text) {
    try {
        const value = JSON.parse(text);
        return Array.isArray(value) ? [...new Set(value.filter(id => typeof id === "string"))] : [];
    } catch (_) { return []; }
}
