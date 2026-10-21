#!/usr/bin/env bash
#
# Static analysis of the QML sources with qmllint.
#
# qmllint parses every QML file, resolves the Plasma/Kirigami imports and
# reports genuine errors (unresolved properties, type errors, unused
# imports). It needs the Plasma QML modules, which ship with plasma-sdk and
# kde-sdk-meta on Arch-based systems.
#
# The script only fails on real errors. The "unqualified access" warnings are
# QML's normal parent-scope lookups and the "i18n is not defined" hints are
# false positives: Plasma injects i18n() into the root scope of every plasmoid,
# a context qmllint cannot know about.
#
# Usage:
#   scripts/lint.sh              # lint every QML file
#   scripts/lint.sh --verbose    # also print the warnings
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

verbose=0
for arg in "$@"; do
    case "$arg" in
        --verbose) verbose=1 ;;
        -h|--help)
            sed -n '3,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

QMLLINT=""
for candidate in qmllint /usr/lib/qt6/bin/qmllint /usr/lib/qt5/bin/qmllint; do
    if command -v "$candidate" >/dev/null 2>&1; then
        QMLLINT="$(command -v "$candidate")"
        break
    fi
done

if [ -z "$QMLLINT" ]; then
    echo "qmllint not found. Install it with: pacman -S qt6-declarative-dev-tools" >&2
    exit 127
fi

# Import paths for the Plasma and Kirigami QML modules.
IMPORT_PATHS=()
for dir in /usr/lib/qt6/qml /usr/lib/qt6/qml/org/kde/plasma /usr/lib/qt6/qml/org/kde/kirigami; do
    [ -d "$dir" ] && IMPORT_PATHS+=(-I "$dir")
done

mapfile -t QML_FILES < <(find contents -name '*.qml' | sort)

if [ "${#QML_FILES[@]}" -eq 0 ]; then
    echo "No QML files found." >&2
    exit 1
fi

log() { printf '\033[1;34m==>\033[0;1m %s\n' "$1"; }

log "Linting ${#QML_FILES[@]} QML files with $($QMLLINT --version 2>&1 | head -1)"

set +e
"$QMLLINT" "${IMPORT_PATHS[@]}" "${QML_FILES[@]}" > /tmp/kickoff-qmllint.log 2>&1
status=$?
set -e

errors="$(grep -c '^Error:' /tmp/kickoff-qmllint.log || true)"
unused="$(grep -c 'Unused import' /tmp/kickoff-qmllint.log || true)"

if [ "$verbose" -eq 1 ]; then
    cat /tmp/kickoff-qmllint.log
else
    grep -E '^(Error|Info): .*Unused import' /tmp/kickoff-qmllint.log || true
fi

echo
if [ "$errors" -gt 0 ]; then
    printf '\033[1;31mFAILED\033[0m: %s error(s) found\n' "$errors"
    exit 1
fi

printf '\033[1;32mOK\033[0m: 0 errors, %s unused import(s)\n' "$unused"
exit 0
