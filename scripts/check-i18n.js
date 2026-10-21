#!/usr/bin/env node
//
// Check that every user-facing string in the QML sources has an entry in the
// Spanish translation catalogue.
//
// Usage: node scripts/check-i18n.js
//
// Exits 0 when the catalogue covers every i18n() string, 1 otherwise.

const fs = require("node:fs");
const path = require("node:path");

const repoRoot = path.resolve(__dirname, "..");
const poPath = path.join(
    repoRoot,
    "contents/locale/es/LC_MESSAGES/kickoff-football.po"
);

function readPO(file) {
    const text = fs.readFileSync(file, "utf8");
    const ids = new Set();

    // Continuation lines of a msgid are appended to the previous value.
    let current = null;
    let collecting = false;

    for (const line of text.split("\n")) {
        const single = line.match(/^msgid\s+"((?:[^"\\]|\\.)*)"\s*$/);
        const plural = line.match(/^msgid_plural\s+"((?:[^"\\]|\\.)*)"\s*$/);
        const continuation = line.match(/^"((?:[^"\\]|\\.)*)"\s*$/);

        if (single || plural) {
            if (current !== null && collecting) ids.add(current);
            const raw = (single || plural)[1];
            current = raw.replace(/\\(.)/g, "$1");
            collecting = true;
        } else if (continuation && collecting) {
            current += continuation[1].replace(/\\(.)/g, "$1");
        } else if (line.trim() === "") {
            if (current !== null && collecting) ids.add(current);
            current = null;
            collecting = false;
        }
    }
    if (current !== null && collecting) ids.add(current);

    // The header entry (empty msgid) is not a translatable string.
    ids.delete("");

    return ids;
}

function qmlFiles(dir) {
    const out = [];
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) out.push(...qmlFiles(full));
        else if (entry.name.endsWith(".qml")) out.push(full);
    }
    return out;
}

function collectStrings() {
    const used = new Map(); // string -> [files]

    const pattern = /\bi18n\(\s*"((?:[^"\\]|\\.)*)"/g;

    for (const file of qmlFiles(path.join(repoRoot, "contents"))) {
        const text = fs.readFileSync(file, "utf8");
        let match;
        while ((match = pattern.exec(text)) !== null) {
            const value = match[1].replace(/\\(.)/g, "$1");
            if (!used.has(value)) used.set(value, []);
            used.get(value).push(path.relative(repoRoot, file));
        }
    }

    return used;
}

const known = readPO(poPath);
const used = collectStrings();

const missing = [...used.entries()]
    .filter(([value]) => !known.has(value))
    .sort((a, b) => a[0].localeCompare(b[0]));

if (missing.length === 0) {
    console.log(`OK: ${used.size} translatable strings, all present in the catalogue.`);
    process.exit(0);
}

console.error(`FAILED: ${missing.length} string(s) missing from the Spanish catalogue:`);
for (const [value, files] of missing) {
    console.error(`  - "${value}"  (${[...new Set(files)].join(", ")})`);
}
console.error("");
console.error("Add them to contents/locale/es/LC_MESSAGES/kickoff-football.po and");
console.error("rebuild the .mo with scripts/check-i18n.sh --write");
process.exit(1);
