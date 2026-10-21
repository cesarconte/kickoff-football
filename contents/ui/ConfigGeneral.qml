import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support
import "Model.js" as Model

KCM.SimpleKCM {
    id: root

    // --- Persistent config bindings ---
    property alias cfg_notify: notifyCheckBox.checked

    // selectedLeagues & followedTeams are stored as JSON strings
    property string cfg_selectedLeagues: ""
    property string cfg_followedTeams: ""

    // Parsed in-memory state (not persisted directly – we write back to cfg_ strings)
    property var selectedLeagues: []
    property var followedTeams: []

    // Search state – leagues
    property var leagueSearchResults: []
    property string leagueSearchQuery: ""
    property bool leagueSearchLoading: false
    property string leagueSearchError: ""
    property int leagueSearchGeneration: 0

    // Search state – clubs
    property var clubSearchResults: []
    property string clubSearchQuery: ""
    property bool clubSearchLoading: false
    property string clubSearchError: ""
    property int clubSearchGeneration: 0

    // -------------------------------------------------------
    // Helpers
    // -------------------------------------------------------
    function saveSelectedLeagues() {
        cfg_selectedLeagues = JSON.stringify(selectedLeagues);
    }

    function saveFollowedTeams() {
        cfg_followedTeams = JSON.stringify(followedTeams);
    }

    function isLeagueSelected(id) {
        return Model.isFollowed(selectedLeagues, id);
    }

    function toggleLeague(league) {
        if (!league || !league.id) return;
        selectedLeagues = Model.toggleFollowed(selectedLeagues, league);
        saveSelectedLeagues();
    }

    function moveLeague(index, direction) {
        var step = Number(direction) < 0 ? -1 : 1;
        var target = Number(index) + step;
        if (target < 0 || target >= selectedLeagues.length) return;
        selectedLeagues = Model.moveItem(selectedLeagues, index, step);
        saveSelectedLeagues();
    }

    function isTeamFollowed(id) {
        return Model.isFollowed(followedTeams, id);
    }

    function toggleFollowTeam(team) {
        if (!team) return;
        followedTeams = Model.toggleFollowed(followedTeams, team);
        saveFollowedTeams();
    }

    // -------------------------------------------------------
    // League search
    // -------------------------------------------------------
    function requestLeagueSearch(term) {
        leagueSearchQuery = String(term || "");
        leagueSearchGeneration++;
        leagueSearchError = "";
        if (leagueSearchQuery.trim().length < 2) {
            leagueSearchResults = [];
            leagueSearchLoading = false;
            leagueSearchDebounce.stop();
            return;
        }
        leagueSearchLoading = true;
        leagueSearchDebounce.restart();
    }

    function runLeagueSearch() {
        var term = leagueSearchQuery.trim();
        if (term.length < 2) { leagueSearchResults = []; leagueSearchLoading = false; return; }
        var gen = leagueSearchGeneration;
        var xhr = new XMLHttpRequest();
        xhr.timeout = 8000;
        xhr.open("GET", Model.searchUrl(term));
        xhr.setRequestHeader("User-Agent", Model.USER_AGENT);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.ontimeout = xhr.onerror = function() {
            if (gen !== root.leagueSearchGeneration) return;
            leagueSearchLoading = false;
            leagueSearchResults = [];
            leagueSearchError = "error";
        };
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || gen !== root.leagueSearchGeneration) return;
            leagueSearchLoading = false;
            if (xhr.status === 200) {
                try { leagueSearchResults = Model.parseLeagueSearch(xhr.responseText); leagueSearchError = ""; }
                catch(e) { leagueSearchResults = []; leagueSearchError = "error"; }
            } else if (xhr.status !== 0) {
                leagueSearchResults = [];
                leagueSearchError = "error";
            }
        };
        xhr.send();
    }

    // -------------------------------------------------------
    // Club search
    // -------------------------------------------------------
    function requestClubSearch(term) {
        clubSearchQuery = String(term || "");
        clubSearchGeneration++;
        clubSearchError = "";
        if (clubSearchQuery.trim().length < 2) {
            clubSearchResults = [];
            clubSearchLoading = false;
            clubSearchDebounce.stop();
            return;
        }
        clubSearchLoading = true;
        clubSearchDebounce.restart();
    }

    function runClubSearch() {
        var term = clubSearchQuery.trim();
        if (term.length < 2) { clubSearchResults = []; clubSearchLoading = false; return; }
        var gen = clubSearchGeneration;
        var xhr = new XMLHttpRequest();
        xhr.timeout = 8000;
        xhr.open("GET", Model.searchUrl(term));
        xhr.setRequestHeader("User-Agent", Model.USER_AGENT);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.ontimeout = xhr.onerror = function() {
            if (gen !== root.clubSearchGeneration) return;
            clubSearchLoading = false;
            clubSearchResults = [];
            clubSearchError = "error";
        };
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || gen !== root.clubSearchGeneration) return;
            clubSearchLoading = false;
            if (xhr.status === 200) {
                try { clubSearchResults = Model.parseSearch(xhr.responseText); clubSearchError = ""; }
                catch(e) { clubSearchResults = []; clubSearchError = "error"; }
            } else if (xhr.status !== 0) {
                clubSearchResults = [];
                clubSearchError = "error";
            }
        };
        xhr.send();
    }

    Timer { id: leagueSearchDebounce; interval: 300; onTriggered: root.runLeagueSearch() }
    Timer { id: clubSearchDebounce;   interval: 300; onTriggered: root.runClubSearch()   }

    // Load stored JSON into in-memory arrays once the component is ready
    Component.onCompleted: {
        try {
            var raw = cfg_selectedLeagues;
            selectedLeagues = raw && raw !== "" ? Model.parseIdList(raw) : Model.parseIdList(Model.FEATURED_LEAGUES);
        } catch(e) {
            selectedLeagues = Model.parseIdList(Model.FEATURED_LEAGUES);
        }
        try {
            var rawT = cfg_followedTeams;
            followedTeams = rawT && rawT !== "" ? JSON.parse(rawT) : [];
        } catch(e) {
            followedTeams = [];
        }
    }

    // -------------------------------------------------------
    // UI
    // -------------------------------------------------------
    Kirigami.FormLayout {
        id: formLayout

        // ── Notifications ────────────────────────────────────
        QQC2.CheckBox {
            id: notifyCheckBox
            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Goal notifications (desktop alert when a followed club scores)")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Competitions")
        }

        // League search field
        Kirigami.SearchField {
            id: leagueSearchField
            Kirigami.FormData.label: i18n("Search:")
            Layout.fillWidth: true
            autoAccept: false
            placeholderText: i18n("Search competitions…")
            onTextChanged: root.requestLeagueSearch(text)
        }

        // League search status / results
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: leagueSearchField.text.trim().length >= 2

            QQC2.Label {
                visible: root.leagueSearchLoading
                text: i18n("Searching competitions…")
                color: Kirigami.Theme.disabledTextColor
            }

            RowLayout {
                visible: root.leagueSearchError !== ""
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon {
                    source: "dialog-warning"
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
                QQC2.Label {
                    text: i18n("Could not search competitions. Try again.")
                    color: Kirigami.Theme.negativeTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                visible: leagueSearchField.text.trim().length >= 2
                    && !root.leagueSearchLoading
                    && root.leagueSearchError === ""
                    && root.leagueSearchResults.length === 0
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon { source: "search"; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: Kirigami.Units.iconSizes.small }
                QQC2.Label { text: i18n("No matching competitions"); color: Kirigami.Theme.disabledTextColor }
            }

            Repeater {
                model: root.leagueSearchResults
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData.name + (modelData.ccode ? " · " + modelData.ccode : "")
                        elide: Text.ElideRight
                    }
                    QQC2.Button {
                        text: root.isLeagueSelected(modelData.id) ? i18n("Selected") : i18n("Add")
                        highlighted: root.isLeagueSelected(modelData.id)
                        onClicked: root.toggleLeague(modelData)
                    }
                }
            }
        }

        // Selected competitions list
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: i18n("Selected competitions (%1)", root.selectedLeagues.length)
                font.bold: true
                color: Kirigami.Theme.disabledTextColor
            }

            Repeater {
                model: root.selectedLeagues
                delegate: RowLayout {
                    id: selLeagueRow
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData.name
                        elide: Text.ElideRight
                    }
                    QQC2.ToolButton {
                        icon.name: "go-up"
                        text: i18n("Move up")
                        display: QQC2.AbstractButton.IconOnly
                        enabled: selLeagueRow.index > 0
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered || activeFocus
                        onClicked: root.moveLeague(selLeagueRow.index, -1)
                    }
                    QQC2.ToolButton {
                        icon.name: "go-down"
                        text: i18n("Move down")
                        display: QQC2.AbstractButton.IconOnly
                        enabled: selLeagueRow.index < root.selectedLeagues.length - 1
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered || activeFocus
                        onClicked: root.moveLeague(selLeagueRow.index, 1)
                    }
                    QQC2.ToolButton {
                        icon.name: "list-remove"
                        text: i18n("Remove")
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered || activeFocus
                        onClicked: root.toggleLeague(modelData)
                    }
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Follow clubs")
        }

        // Club search field
        Kirigami.SearchField {
            id: clubSearchField
            Kirigami.FormData.label: i18n("Search:")
            Layout.fillWidth: true
            autoAccept: false
            placeholderText: i18n("Search clubs…")
            onTextChanged: root.requestClubSearch(text)
        }

        // Club search status / results
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: clubSearchField.text.trim().length >= 2

            QQC2.Label {
                visible: root.clubSearchLoading
                text: i18n("Searching clubs…")
                color: Kirigami.Theme.disabledTextColor
            }

            RowLayout {
                visible: root.clubSearchError !== ""
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon { source: "dialog-warning"; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: Kirigami.Units.iconSizes.small }
                QQC2.Label {
                    text: i18n("Could not search clubs. Try again.")
                    color: Kirigami.Theme.negativeTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                visible: clubSearchField.text.trim().length >= 2
                    && !root.clubSearchLoading
                    && root.clubSearchError === ""
                    && root.clubSearchResults.length === 0
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon { source: "search"; implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: Kirigami.Units.iconSizes.small }
                QQC2.Label { text: i18n("No matching clubs"); color: Kirigami.Theme.disabledTextColor }
            }

            Repeater {
                model: root.clubSearchResults
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Image {
                        width: 20; height: 20
                        source: Model.teamLogoUrl(modelData.id)
                        sourceSize.width: 64; sourceSize.height: 64
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: modelData.name
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: modelData.leagueName || ""
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }
                    QQC2.Button {
                        text: root.isTeamFollowed(modelData.id) ? i18n("Following") : i18n("Follow")
                        highlighted: root.isTeamFollowed(modelData.id)
                        onClicked: root.toggleFollowTeam(modelData)
                    }
                }
            }
        }

        // Followed clubs list
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: i18n("Followed clubs (%1)", root.followedTeams.length)
                font.bold: true
                color: Kirigami.Theme.disabledTextColor
            }

            QQC2.Label {
                visible: root.followedTeams.length === 0
                text: i18n("Search for clubs above to follow them and receive goal notifications.")
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
                Layout.fillWidth: true
            }

            Repeater {
                model: root.followedTeams
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Image {
                        width: 18; height: 18
                        source: Model.teamLogoUrl(modelData.id)
                        sourceSize.width: 48; sourceSize.height: 48
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData.name
                        elide: Text.ElideRight
                    }
                    QQC2.ToolButton {
                        icon.name: "list-remove"
                        text: i18n("Unfollow")
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered || activeFocus
                        onClicked: root.toggleFollowTeam(modelData)
                    }
                }
            }
        }
    }
}
