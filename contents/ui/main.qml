import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.icon: "trophy-symbolic"
    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Kickoff Football")
    toolTipSubText: kickoffBackend.barText

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
        }
    }
}
