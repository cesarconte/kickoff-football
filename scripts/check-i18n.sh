#!/usr/bin/env bash
#
# Verify that the Spanish translation is complete and compiled.
#
# Two checks:
#   1. Every i18n() string in the QML sources has an entry in the .po catalogue.
#   2. The committed .mo file is exactly what msgfmt produces from that .po,
#      so a translated string can never silently go missing.
#
# Usage:
#   scripts/check-i18n.sh           # verify only
#   scripts/check-i18n.sh --write   # rebuild the .mo from the .po, then verify
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

PO="contents/locale/es/LC_MESSAGES/kickoff-football.po"
MO="contents/locale/es/LC_MESSAGES/plasma_applet_org.kde.plasma.kickoff-football.mo"

do_write=0
for arg in "$@"; do
    case "$arg" in
        --write) do_write=1 ;;
        -h|--help)
            sed -n '3,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

if ! command -v msgfmt >/dev/null 2>&1; then
    echo "msgfmt not found. Install it with: pacman -S gettext" >&2
    exit 127
fi

log() { printf '\033[1;34m==>\033[0;1m %s\n' "$1"; }

if [ "$do_write" -eq 1 ]; then
    log "Compiling $PO"
    msgfmt --check --statistics -o "$MO" "$PO"
fi

# 1. Coverage of the catalogue.
log "Checking translation coverage"
node scripts/check-i18n.js

# 2. The .mo must match the .po byte for byte.
log "Checking that the compiled catalogue is up to date"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
msgfmt -o "$tmp/expected.mo" "$PO"

if ! cmp -s "$tmp/expected.mo" "$MO"; then
    echo "FAILED: $MO is not in sync with $PO." >&2
    echo "Rebuild it with: scripts/check-i18n.sh --write" >&2
    exit 1
fi

echo "OK: the compiled catalogue matches the source catalogue."
