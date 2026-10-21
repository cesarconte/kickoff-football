import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.icon: Qt.resolvedUrl("../icon.svg")
    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Kickoff Football")
    toolTipSubText: kickoffBackend.barTooltipText

    KickoffBackend {
        id: kickoffBackend
    }

    compactRepresentation: CompactRepresentation {
        backend: kickoffBackend
        onToggleRequested: root.expanded = !root.expanded
        onRefreshRequested: kickoffBackend.refreshMatches()
    }

    fullRepresentation: FullRepresentation {
        backend: kickoffBackend
        popupOpen: root.expanded
    }

    onExpandedChanged: {
        if (root.expanded) {
            kickoffBackend.refreshMatches();
            if (kickoffBackend.matchDetail && kickoffBackend.matchDetail.id) {
                kickoffBackend.loadMatch(kickoffBackend.matchDetail.id, true);
            }
        } else {
            kickoffBackend.jumpToday();
        }
    }
}
