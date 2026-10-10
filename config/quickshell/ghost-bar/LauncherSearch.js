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
    const words = query.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean);
    return entries.filter(e => !e.noDisplay && e.name).map(entry => {
        const name = entry.name.toLocaleLowerCase();
        const extra = [entry.genericName || "", ...(entry.keywords || [])].join(" ").toLocaleLowerCase();
        let score = 0;
        for (const word of words) {
            if (name === word) score += 100;
            else if (name.startsWith(word)) score += 60;
            else if (name.includes(word)) score += 30;
            else if (extra.includes(word)) score += 10;
            else return {entry, score: -1};
        }
        return {entry, score};
    }).filter(hit => hit.score >= 0).sort((a, b) =>
        b.score - a.score || Number(pins.includes(b.entry.id)) - Number(pins.includes(a.entry.id)) ||
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
