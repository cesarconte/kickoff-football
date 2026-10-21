#!/usr/bin/env node
//
// Validate the plasmoid package structure and metadata.
//
// A broken metadata.json or a missing file makes Plasma refuse to load the
// widget entirely, with an error that is hard to trace back to the package.
//
// Usage: node scripts/check-package.js
//
// Exits 0 when the package is valid, 1 otherwise.

const fs = require("node:fs");
const path = require("node:path");

const repoRoot = path.resolve(__dirname, "..");
const EXPECTED_ID = "org.kde.plasma.kickoff-football";

const problems = [];

function fail(message) {
    problems.push(message);
}

function readJSON(relative) {
    const full = path.join(repoRoot, relative);
    if (!fs.existsSync(full)) {
        fail(`${relative} is missing`);
        return null;
    }
    try {
        return JSON.parse(fs.readFileSync(full, "utf8"));
    } catch (error) {
        fail(`${relative} is not valid JSON: ${error.message}`);
        return null;
    }
}

// 1. metadata.json
const metadata = readJSON("metadata.json");

if (metadata) {
    const plugin = metadata.KPlugin || {};

    for (const key of ["Id", "Name", "Description", "Icon", "License", "Version"]) {
        if (!plugin[key]) fail(`metadata.json: KPlugin.${key} is missing or empty`);
    }

    if (plugin.Id && plugin.Id !== EXPECTED_ID) {
        fail(`metadata.json: KPlugin.Id is "${plugin.Id}", expected "${EXPECTED_ID}"`);
    }

    if (!metadata.KPackageStructure) {
        fail("metadata.json: KPackageStructure is missing");
    } else if (metadata.KPackageStructure !== "Plasma/Applet") {
        fail(`metadata.json: KPackageStructure is "${metadata.KPackageStructure}", expected "Plasma/Applet"`);
    }

    if (!Array.isArray(plugin.Authors) || plugin.Authors.length === 0) {
        fail("metadata.json: KPlugin.Authors must be a non-empty array");
    }
}

// 2. Required files of the package
const requiredFiles = [
    "contents/ui/main.qml",
    "contents/ui/CompactRepresentation.qml",
    "contents/ui/FullRepresentation.qml",
    "contents/config/config.qml",
    "contents/config/main.xml",
    "contents/icon.svg",
    "contents/locale/es/LC_MESSAGES/kickoff-football.po",
    "contents/locale/es/LC_MESSAGES/plasma_applet_org.kde.plasma.kickoff-football.mo",
];

for (const relative of requiredFiles) {
    if (!fs.existsSync(path.join(repoRoot, relative))) {
        fail(`${relative} is missing`);
    }
}

// 3. contents/ must only contain the directories and files the package needs,
//    so that nothing unexpected ends up in the installed payload.
const ALLOWED_IN_CONTENTS = new Set(["ui", "config", "locale", "images", "icon.svg"]);

for (const entry of fs.readdirSync(path.join(repoRoot, "contents"), { withFileTypes: true })) {
    if (!ALLOWED_IN_CONTENTS.has(entry.name)) {
        fail(`unexpected entry inside contents/: ${entry.name}`);
    }
}

if (problems.length === 0) {
    console.log("OK: the plasmoid package is valid.");
    process.exit(0);
}

console.error(`FAILED: ${problems.length} package problem(s):`);
for (const problem of problems) console.error(`  - ${problem}`);
process.exit(1);
