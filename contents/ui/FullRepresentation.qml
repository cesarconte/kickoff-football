import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import "Model.js" as Model

Item {
    id: root


    required property var backend
    property bool popupOpen: false

    property string page: "list"      // "list" | "match"
    property string tab: "matches"    // "matches" | "following" | "table"
    property string selectedMatchId: ""

    readonly property string tableLeagueName: {
        for (var i = 0; i < backend.tableLeagues.length; i++) {
            if (String(backend.tableLeagues[i].id) === String(backend.tableLeagueId))
                return backend.tableLeagues[i].name;
        }
        return backend.table.name || "";
    }

    readonly property color foreground: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.Theme.disabledTextColor
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color urgent: Kirigami.Theme.negativeTextColor

    // Translation maps for API data (FotMob returns English)
    readonly property var statTranslations: ({
        "ball possession": i18n("Ball possession"),
        "expected goals (xg)": i18n("Expected goals (xG)"),
        "total shots": i18n("Total shots"),
        "shots on target": i18n("Shots on target"),
        "shots off target": i18n("Shots off target"),
        "blocked shots": i18n("Blocked shots"),
        "big chances": i18n("Big chances"),
        "big chances missed": i18n("Big chances missed"),
        "accurate passes": i18n("Accurate passes"),
        "fouls committed": i18n("Fouls committed"),
        "corners": i18n("Corners"),
        "offsides": i18n("Offsides"),
        "touches in opposition box": i18n("Touches in opposition box"),
        "goalkeeper saves": i18n("Goalkeeper saves"),
        "yellow cards": i18n("Yellow cards"),
        "red cards": i18n("Red cards"),
        "crosses": i18n("Crosses"),
        "tackles won": i18n("Tackles won"),
        "interceptions": i18n("Interceptions"),
        "clearances": i18n("Clearances"),
        "duels won": i18n("Duels won"),
        "ground duels won": i18n("Ground duels won"),
        "aerial duels won": i18n("Aerial duels won"),
        "passes into final third": i18n("Passes into final third"),
        "long balls": i18n("Long balls"),
        "hit woodwork": i18n("Hit woodwork"),
        "counter attacks": i18n("Counter attacks"),
        "xg first half": i18n("xG first half"),
        "xg second half": i18n("xG second half")
    })

    readonly property var eventTranslations: ({
        "yellow": i18n("Yellow"),
        "red": i18n("Red"),
        "yellowred": i18n("Yellow-Red"),
        "og": i18n("OG"),
        "ht": i18n("HT"),
        "ft": i18n("FT")
    })


    readonly property bool compactFollowingEmpty: root.page === "list"
        && root.tab === "following"
        && backend.followedMatches.length === 0
    implicitWidth: compactFollowingEmpty ? 360 : 420
    implicitHeight: 560
    Layout.minimumWidth: compactFollowingEmpty ? 340 : 380
    Layout.preferredWidth: compactFollowingEmpty ? 360 : 420
    Layout.minimumHeight: 480
    Layout.preferredHeight: 560

    function showList() {
        page = "list";
    }

    function openMatch(match) {
        if (!match) return;
        selectedMatchId = String(match.id);
        page = "match";
        backend.loadMatch(match.id);
    }

    function setTab(newTab) {
        tab = newTab;
        if (newTab === "table" && backend.tableLeagues.length > 0 && (!backend.table || !backend.table.rows || backend.table.rows.length === 0)) {
            backend.loadTable(backend.tableLeagueId || backend.preferredTableLeagueId);
        }
    }

    function shiftTableLeague(direction) {
        var next = Model.adjacentCompetition(backend.tableLeagues, backend.tableLeagueId, direction);
        if (next) backend.loadTable(next.id);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: 8

        // Top Navigation Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PlasmaComponents3.ToolButton {
                visible: root.page !== "list"
                icon.name: "go-previous"
                text: i18n("Back")
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: root.showList()
            }

            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: root.page === "match"
                    ? (backend.matchDetail ? backend.matchDetail.leagueName : i18n("Match Detail"))
                    : i18n("Kickoff Football")
                color: root.foreground
                font.bold: true
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 2
                elide: Text.ElideRight
            }

            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                text: i18n("Refresh")
                display: PlasmaComponents3.AbstractButton.IconOnly
                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered || activeFocus
                onClicked: {
                    if (root.page === "match" && root.selectedMatchId) {
                        backend.loadMatch(root.selectedMatchId);
                        backend.refreshMatches();
                    } else if (root.tab === "table") {
                        backend.loadTable(backend.tableLeagueId);
                    } else {
                        backend.refreshMatches();
                    }
                }
            }
        }

        // Subheader (Dates + Tabs for List page)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.page === "list"

            // Date selector
            RowLayout {
                Layout.fillWidth: true
                visible: root.tab !== "table"
                spacing: 4

                PlasmaComponents3.ToolButton {
                    icon.name: "go-previous"
                    text: i18n("Previous day")
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered || activeFocus
                    onClicked: backend.shiftDate(-1)
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24

                    PlasmaComponents3.ToolButton {
                        anchors.centerIn: parent
                        text: Model.dateHeading(backend.dateKey, backend.todayKey, {
                            today: i18n("Today"),
                            yesterday: i18n("Yesterday"),
                            tomorrow: i18n("Tomorrow"),
                            days: [i18n("Sun"), i18n("Mon"), i18n("Tue"), i18n("Wed"), i18n("Thu"), i18n("Fri"), i18n("Sat")],
                            months: [i18n("Jan"), i18n("Feb"), i18n("Mar"), i18n("Apr"), i18n("May"), i18n("Jun"), i18n("Jul"), i18n("Aug"), i18n("Sep"), i18n("Oct"), i18n("Nov"), i18n("Dec")]
                        })
                        onClicked: backend.jumpToday()
                    }
                }

                PlasmaComponents3.ToolButton {
                    icon.name: "go-next"
                    text: i18n("Next day")
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    QQC2.ToolTip.text: text
                            QQC2.ToolTip.visible: hovered || activeFocus
                    onClicked: backend.shiftDate(1)
                }
            }

            // Tabs (Matches | Following | Table)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: i18n("MATCHES")
                    highlighted: root.tab === "matches"
                    onClicked: root.setTab("matches")
                }

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: i18n("FOLLOWING")
                    highlighted: root.tab === "following"
                    onClicked: root.setTab("following")
                }

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: i18n("TABLE")
                    highlighted: root.tab === "table"
                    onClicked: root.setTab("table")
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // ---- PAGE 1: LIST VIEW ----
        QQC2.ScrollView {
            id: listScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.page === "list"
            clip: true
            contentWidth: availableWidth
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

            ColumnLayout {
                width: listScrollView.availableWidth
                spacing: 12

                // Matches tab content
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.tab === "matches"
                    spacing: 10

                    Text {
                        textFormat: Text.PlainText
                        visible: backend.refreshing && (!backend.visibleLeagues || backend.visibleLeagues.length === 0)
                        text: i18n("Loading matches…")
                        color: root.dim
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: backend.lastError !== ""
                        text: backend.lastError
                        color: root.urgent
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: !backend.refreshing && (!backend.visibleLeagues || backend.visibleLeagues.length === 0) && backend.lastError === ""
                        text: i18n("No matches scheduled for this date.")
                        color: root.dim
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Repeater {
                        model: root.tab === "matches" ? backend.visibleLeagues : []
                        delegate: ColumnLayout {
                            id: leagueBlock
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 6

                            // League Header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Image {
                                    width: 16
                                    height: 16
                                    source: Model.leagueLogoUrl(leagueBlock.modelData.primaryId || leagueBlock.modelData.id)
                                    sourceSize.width: 48
                                    sourceSize.height: 48
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    textFormat: Text.PlainText
                                    text: leagueBlock.modelData.name
                                    color: leagueBlock.modelData.pinned ? root.accent : root.dim
                                    font.bold: true
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                }

                                Text {
                                    textFormat: Text.PlainText
                                    visible: leagueBlock.modelData.country !== ""
                                    text: "· " + leagueBlock.modelData.country
                                    color: root.dim
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                }

                                Item { Layout.fillWidth: true }
                            }

                            // Match rows in this league
                            Repeater {
                                model: leagueBlock.modelData.matches
                                delegate: MatchRow {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    match: modelData
                                    goalFlashIds: backend.goalFlashIds
                                    showCompetition: leagueBlock.modelData.pinned === true
                                    onClicked: root.openMatch(modelData)
                                }
                            }
                        }
                    }
                }

                // Following tab content
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.tab === "following"
                    spacing: 10

                    Text {
                        textFormat: Text.PlainText
                        visible: backend.followedTeams.length === 0
                        Layout.fillWidth: true
                        text: i18n("Follow your favorite clubs in Settings to pin their matches here and receive goal notifications.")
                        color: root.dim
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: backend.followedTeams.length > 0 && backend.followedMatches.length === 0
                        Layout.fillWidth: true
                        text: i18n("None of your followed clubs play on this date.")
                        color: root.dim
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: root.tab === "following" ? backend.followedMatches : []
                        delegate: MatchRow {
                            required property var modelData
                            Layout.fillWidth: true
                            match: modelData
                            goalFlashIds: backend.goalFlashIds
                            showCompetition: true
                            onClicked: root.openMatch(modelData)
                        }
                    }
                }

                // Table / Standings tab content
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.tab === "table"
                    spacing: 8

                    Text {
                        textFormat: Text.PlainText
                        visible: backend.tableLeagues.length === 0
                        text: i18n("Select leagues in Settings to view their standings.")
                        color: root.dim
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // Use the same previous/next pattern as the date selector.
                    RowLayout {
                        Layout.fillWidth: true
                        visible: backend.tableLeagues.length > 0
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents3.ToolButton {
                            icon.name: "go-previous"
                            text: i18n("Previous competition")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            enabled: backend.tableLeagues.length > 1
                            QQC2.ToolTip.text: text
                            QQC2.ToolTip.visible: hovered || activeFocus
                            onClicked: root.shiftTableLeague(-1)
                        }

                        Text {
                            textFormat: Text.PlainText
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: root.tableLeagueName
                            color: root.foreground
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: "go-next"
                            text: i18n("Next competition")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            enabled: backend.tableLeagues.length > 1
                            QQC2.ToolTip.text: text
                            QQC2.ToolTip.visible: hovered || activeFocus
                            onClicked: root.shiftTableLeague(1)
                        }
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: backend.tableLoading
                        text: i18n("Loading standings…")
                        color: root.dim
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: backend.tableError !== ""
                        text: backend.tableError
                        color: root.urgent
                    }

                    // Standings Table Header (RowLayout with fillWidth eliminates binding and polish loops)
                    RowLayout {
                        Layout.fillWidth: true
                        visible: backend.table.rows && backend.table.rows.length > 0
                        spacing: 8

                        Item { Layout.preferredWidth: 3 }
                        Text {
                            textFormat: Text.PlainText
                            Layout.preferredWidth: 20
                            text: "#"
                            color: root.dim
                            font.bold: true
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        }
                        Text {
                            textFormat: Text.PlainText
                            Layout.fillWidth: true
                            text: i18n("CLUB")
                            color: root.dim
                            font.bold: true
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        }
                        Text {
                            textFormat: Text.PlainText
                            Layout.preferredWidth: 28
                            text: "P"
                            color: root.dim
                            font.bold: true
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            textFormat: Text.PlainText
                            Layout.preferredWidth: 36
                            text: "GD"
                            color: root.dim
                            font.bold: true
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            textFormat: Text.PlainText
                            Layout.preferredWidth: 36
                            Layout.rightMargin: Kirigami.Units.smallSpacing
                            text: "PTS"
                            color: root.dim
                            font.bold: true
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Table rows (RowLayout with fillWidth eliminates binding and polish loops)
                    Repeater {
                        model: root.tab === "table" ? (backend.table.rows || []) : []
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 26
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.fillHeight: true
                                Layout.topMargin: 4
                                Layout.bottomMargin: 4
                                color: modelData.qualColor || "transparent"
                                radius: 1
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.preferredWidth: 20
                                text: String(modelData.pos)
                                color: root.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.fillWidth: true
                                text: modelData.name
                                color: root.foreground
                                elide: Text.ElideRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.preferredWidth: 28
                                text: String(modelData.played)
                                color: root.dim
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.preferredWidth: 36
                                text: (Number(modelData.gd) > 0 ? "+" : "") + String(modelData.gd)
                                color: root.dim
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.preferredWidth: 36
                                Layout.rightMargin: Kirigami.Units.smallSpacing
                                text: String(modelData.pts)
                                color: root.foreground
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }

        // ---- PAGE 2: MATCH DETAIL VIEW ----
        QQC2.ScrollView {
            id: matchScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.page === "match"
            clip: true

            ColumnLayout {
                width: matchScrollView.width - 12
                spacing: 14

                Text {
                    textFormat: Text.PlainText
                    visible: backend.detailLoading && !backend.matchDetail
                    text: i18n("Loading match details…")
                    color: root.dim
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    textFormat: Text.PlainText
                    visible: backend.detailError !== ""
                    text: backend.detailError
                    color: root.urgent
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: backend.matchDetail !== null
                    spacing: 12

                    // Big Match Card (Home vs Away)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        radius: 8
                        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // Home club
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Image {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 44
                                    height: 44
                                    source: backend.matchDetail ? backend.matchDetail.home.imageUrl : ""
                                    sourceSize.width: 96
                                    sourceSize.height: 96
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }

                                Text {
                                    textFormat: Text.PlainText
                                    Layout.fillWidth: true
                                    text: backend.matchDetail ? backend.matchDetail.home.name : ""
                                    color: root.foreground
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }

                            // Score & Clock
                            ColumnLayout {
                                Layout.preferredWidth: 80
                                spacing: 2

                                Text {
                                    textFormat: Text.PlainText
                                    Layout.fillWidth: true
                                    text: backend.matchDetail ? Model.scoreLabel(backend.matchDetail) : ""
                                    color: root.foreground
                                    font.bold: true
                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 8
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    textFormat: Text.PlainText
                                    Layout.fillWidth: true
                                    text: backend.matchDetail ? backend.matchDetail.clock : ""
                                    color: backend.matchDetail && backend.matchDetail.state === "live" ? root.accent : root.dim
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            // Away club
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Image {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 44
                                    height: 44
                                    source: backend.matchDetail ? backend.matchDetail.away.imageUrl : ""
                                    sourceSize.width: 96
                                    sourceSize.height: 96
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }

                                Text {
                                    textFormat: Text.PlainText
                                    Layout.fillWidth: true
                                    text: backend.matchDetail ? backend.matchDetail.away.name : ""
                                    color: root.foreground
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    // Follow Home / Away buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        PlasmaComponents3.Button {
                            text: backend.matchDetail && backend.isTeamFollowed(backend.matchDetail.home.id) ? i18n("Following Home") : i18n("Follow Home")
                            highlighted: backend.matchDetail && backend.isTeamFollowed(backend.matchDetail.home.id)
                            onClicked: if (backend.matchDetail) backend.toggleFollowTeam(backend.matchDetail.home)
                        }

                        PlasmaComponents3.Button {
                            text: backend.matchDetail && backend.isTeamFollowed(backend.matchDetail.away.id) ? i18n("Following Away") : i18n("Follow Away")
                            highlighted: backend.matchDetail && backend.isTeamFollowed(backend.matchDetail.away.id)
                            onClicked: if (backend.matchDetail) backend.toggleFollowTeam(backend.matchDetail.away)
                        }
                    }

                    Kirigami.Separator { Layout.fillWidth: true }

                    // Timeline / Match Events (Goals, Cards)
                    Text {
                        textFormat: Text.PlainText
                        text: i18n("Match Events")
                        color: root.dim
                        font.bold: true
                        visible: backend.matchDetail && backend.matchDetail.events && backend.matchDetail.events.length > 0
                    }

                    Repeater {
                        model: backend.matchDetail ? backend.matchDetail.events : []
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                textFormat: Text.PlainText
                                Layout.preferredWidth: 40
                                text: modelData.clock
                                color: modelData.type === "Goal" ? root.accent : root.dim
                                font.bold: modelData.type === "Goal"
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.fillWidth: true
                                text: (modelData.type === "Goal" ? "⚽ " : (modelData.card === "Yellow" ? "🟨 " : (modelData.card === "Red" ? "🟥 " : ""))) + Model.translateEventLabel(modelData, root.eventTranslations)
                                color: modelData.isHome ? root.foreground : root.dim
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                        visible: backend.matchDetail && backend.matchDetail.stats && backend.matchDetail.stats.length > 0
                    }

                    // Match Statistics
                    Text {
                        textFormat: Text.PlainText
                        text: i18n("Statistics")
                        color: root.dim
                        font.bold: true
                        visible: backend.matchDetail && backend.matchDetail.stats && backend.matchDetail.stats.length > 0
                    }

                    Repeater {
                        model: backend.matchDetail ? backend.matchDetail.stats : []
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                textFormat: Text.PlainText
                                Layout.preferredWidth: 72
                                text: String(modelData.home)
                                color: root.foreground
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.fillWidth: true
                                text: Model.translateStat(modelData.title, root.statTranslations)
                                color: root.dim
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.preferredWidth: 72
                                text: String(modelData.away)
                                color: root.foreground
                                font.bold: true
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Open in web browser
                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        icon.name: "internet-web-browser"
                        text: i18n("Open Match in FotMob")
                        onClicked: backend.openMatchInBrowser(root.selectedMatchId)
                    }
                }
            }
        }

    }
}
