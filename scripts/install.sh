#!/usr/bin/env bash
#
# Install or update the Kickoff Football plasmoid for the current user.
#
# This is the canonical way to keep the installed plasmoid in sync with
# GitHub: it fast-forwards this repository to origin/main, copies the
# plasmoid payload into the user plasmoids directory and reloads Plasma.
#
# The installed folder is a plain directory (not a symlink and not a clone),
# so it contains only the plasmoid package: metadata.json + contents/.
# The widget configuration itself lives in Plasma's applet configuration,
# not in this folder, and is therefore never touched.
#
# Usage:
#   scripts/install.sh              # pull from GitHub, install, reload Plasma
#   scripts/install.sh --no-pull    # install the current working tree as is
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLASMOID_ID="org.kde.plasma.kickoff-football"
PLASMOIDS_DIR="${PLASMASHELL_PLASMOIDS_DIR:-$HOME/.local/share/plasma/plasmoids}"
PLASMOID_DIR="$PLASMOIDS_DIR/$PLASMOID_ID"

do_pull=1
for arg in "$@"; do
    case "$arg" in
        --no-pull) do_pull=0 ;;
        -h|--help)
            sed -n '3,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }

# 1. Bring the repository up to date with GitHub.
if [ "$do_pull" -eq 1 ] && git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    if [ -n "$(git -C "$REPO_DIR" status --porcelain)" ]; then
        echo "Working tree has local changes; skipping git pull." >&2
    else
        log "Pulling latest changes from GitHub"
        git -C "$REPO_DIR" pull --ff-only
    fi
fi

# 2. Replace the installed package with the current repository contents.
#    A symlink is removed rather than followed, so this never writes
#    through to an unrelated directory.
if [ -L "$PLASMOID_DIR" ]; then
    log "Removing symlinked plasmoid at $PLASMOID_DIR"
    rm -f "$PLASMOID_DIR"
fi
if [ -e "$PLASMOID_DIR" ]; then
    rm -rf "$PLASMOID_DIR"
fi

log "Installing plasmoid into $PLASMOID_DIR"
mkdir -p "$PLASMOID_DIR"
cp -a "$REPO_DIR/metadata.json" "$PLASMOID_DIR/metadata.json"
cp -a "$REPO_DIR/contents" "$PLASMOID_DIR/contents"

# 3. Reload Plasma so the panel picks up the new files.
log "Restarting plasmashell"
systemctl --user restart plasma-plasmashell.service

log "Done. Installed version: $(sed -n 's/.*"Version": "\(.*\)".*/\1/p' "$PLASMOID_DIR/metadata.json")"
