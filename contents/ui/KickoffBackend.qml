import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "Model.js" as Model

Item {
    id: root

    property string dateKey: Model.dateKeyFromDate(new Date())
    property string todayKey: Model.dateKeyFromDate(new Date())
    property var leagues: []
    property bool refreshing: false
    property bool refreshPending: false
    property string lastError: ""
    property date lastUpdated: new Date(0)

    property var matchDetail: null
    property bool detailLoading: false
    property string detailError: ""

    property var table: ({ name: "", rows: [] })
    property string tableLeagueId: ""
    property bool tableLoading: false
    property string tableError: ""

    property var searchResults: []
    property string searchQuery: ""
    property bool searchLoading: false
    property var leagueSearchResults: []
    property string leagueSearchQuery: ""
    property bool leagueSearchLoading: false

    property var goalFlashIds: ({})
    property var _previousScores: null

    signal goalScored(var event)
    signal matchEnded(var event)

    // Configuration bindings
    readonly property bool notify: plasmoid.configuration.notify !== false
    
    // Followed teams parsed from configuration string
    property var followedTeams: []
    property var selectedLeagues: []
    readonly property var tableLeagues: Model.competitionChoices(selectedLeagues, followedTeams)
    readonly property string preferredTableLeagueId: followedTeams.length && followedTeams[0].leagueId
        ? String(followedTeams[0].leagueId)
        : (selectedLeagues.length ? String(selectedLeagues[0].id) : "")

    readonly property var visibleLeagues: Model.pinFollowed(
        Model.filterLeagues(leagues, selectedLeagues, followedTeams, "selected"),
        followedTeams
    )
    readonly property var followedMatches: Model.followingMatches(leagues, followedTeams)
    readonly property var live: Model.liveMatches(leagues)
    readonly property int liveCount: live.length
    readonly property var headline: Model.barHeadline(leagues, followedTeams)
    readonly property string barText: headline ? headline.text : "Kickoff"
    readonly property string barTooltipText: headline && headline.count > 1
        ? i18ncp("football match count", "%1 match is currently live", "%1 matches are currently live", headline.count)
        : barText
    readonly property bool barLive: headline ? headline.live === true : false
    readonly property int pollMs: liveCount > 0 ? 20000 : 180000

    function loadFollowedTeams() {
        try {
            var raw = plasmoid.configuration.followedTeams;
            if (!raw || raw === "") {
                followedTeams = [];
            } else if (typeof raw === "string") {
                followedTeams = JSON.parse(raw);
            } else if (Array.isArray(raw)) {
                followedTeams = raw;
            }
        } catch (e) {
            console.warn("Could not parse followedTeams config:", e);
            followedTeams = [];
        }
    }

    function saveFollowedTeams() {
        plasmoid.configuration.followedTeams = JSON.stringify(followedTeams);
    }

    function loadSelectedLeagues() {
        try {
            var raw = plasmoid.configuration.selectedLeagues;
            selectedLeagues = raw ? Model.parseIdList(raw) : Model.parseIdList(Model.FEATURED_LEAGUES);
        } catch (e) {
            console.warn("Could not parse selectedLeagues config:", e);
            selectedLeagues = Model.parseIdList(Model.FEATURED_LEAGUES);
        }
    }

    function saveSelectedLeagues() {
        plasmoid.configuration.selectedLeagues = JSON.stringify(selectedLeagues);
        if (tableLeagues.length === 0) {
            tableLeagueId = "";
            table = ({ name: "", rows: [] });
            tableError = "";
            tableLoading = false;
        } else if (!Model.isFollowed(tableLeagues, tableLeagueId)) {
            loadTable(preferredTableLeagueId || tableLeagues[0].id);
        }
        refreshMatches();
    }

    function toggleLeague(league) {
        if (!league || !league.id) return;
        selectedLeagues = Model.toggleFollowed(selectedLeagues, league);
        saveSelectedLeagues();
    }

    function isLeagueSelected(leagueId) {
        return Model.isFollowed(selectedLeagues, leagueId);
    }

    function isTeamFollowed(teamId) {
        return Model.isFollowed(followedTeams, teamId);
    }

    function toggleFollowTeam(team) {
        if (!team) return;
        followedTeams = Model.toggleFollowed(followedTeams, team);
        saveFollowedTeams();
    }

    function refreshMatches() {
        if (refreshing) {
            refreshPending = true;
            return;
        }
        refreshing = true;
        lastError = "";
        todayKey = Model.dateKeyFromDate(new Date());

        var url = Model.matchesUrl(dateKey);
        var xhr = new XMLHttpRequest();
        xhr.timeout = 10000;
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", Model.USER_AGENT);
        xhr.setRequestHeader("Accept", "application/json");

        function handleRefreshError(msg) {
            lastError = msg;
            refreshing = false;
            if (refreshPending) {
                refreshPending = false;
                Qt.callLater(refreshMatches);
            }
        }

        xhr.ontimeout = function() {
            handleRefreshError("Score feed request timed out");
        };

        xhr.onerror = function() {
            handleRefreshError("Network error reaching score feed");
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        applyMatches(xhr.responseText);
                    } catch (err) {
                        console.warn("Kickoff: Error applying matches:", err);
                        handleRefreshError("Could not process match data");
                    }
                } else if (xhr.status !== 0) {
                    handleRefreshError("Could not reach score feed (" + xhr.status + ")");
                }
            }
        };
        xhr.send();
    }

    function applyMatches(raw) {
        var parsed = Model.parseMatches(raw);
        if (!parsed.ok) {
            lastError = parsed.error || "Could not parse matches";
            refreshing = false;
            return;
        }

        var current = Model.scoreSnapshot(parsed.leagues);
        if (_previousScores) {
            try {
                if (notify) {
                    var toasts = Model.goalEvents(_previousScores, current, followedTeams);
                    for (var t = 0; t < toasts.length; t++) {
                        sendToast(toasts[t].headline, toasts[t].description);
                    }
                }
                var celebrations = Model.celebrationEvents(_previousScores, current, followedTeams);
                for (var c = 0; c < celebrations.length; c++) {
                    noteGoal(celebrations[c]);
                }
                var endings = Model.fullTimeEvents(_previousScores, current, followedTeams);
                for (var e = 0; e < endings.length; e++) {
                    matchEnded(endings[e]);
                    if (notify) {
                        sendToast("Full Time", endings[e].headline);
                    }
                }
            } catch (eventErr) {
                console.warn("Kickoff: Error processing match events:", eventErr);
            }
        }
        _previousScores = current;
        leagues = parsed.leagues;
        lastUpdated = new Date();
        lastError = "";
        refreshing = false;
        if (refreshPending) {
            refreshPending = false;
            Qt.callLater(refreshMatches);
        }
    }

    function setDateKey(key) {
        var next = String(key || Model.dateKeyFromDate(new Date()));
        if (next === dateKey) {
            refreshMatches();
            return;
        }
        dateKey = next;
        refreshMatches();
    }

    function shiftDate(days) {
        setDateKey(Model.shiftDateKey(dateKey, days));
    }

    function jumpToday() {
        setDateKey(Model.dateKeyFromDate(new Date()));
    }

    function loadMatch(matchId) {
        var id = String(matchId || "");
        if (!id) return;
        detailLoading = true;
        detailError = "";
        matchDetail = matchDetail && String(matchDetail.id) === id ? matchDetail : null;

        var url = Model.matchDetailsUrl(id);
        var xhr = new XMLHttpRequest();
        xhr.timeout = 10000;
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", Model.USER_AGENT);
        xhr.setRequestHeader("Accept", "application/json");

        function handleMatchError(msg) {
            detailError = msg;
            detailLoading = false;
        }

        xhr.ontimeout = function() {
            handleMatchError("Match details timed out");
        };

        xhr.onerror = function() {
            handleMatchError("Network error loading match details");
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var parsed = Model.parseMatchDetails(xhr.responseText);
                        if (parsed.ok && parsed.match) {
                            matchDetail = parsed.match;
                            detailError = "";
                        } else {
                            detailError = parsed.error || "Could not read match details";
                        }
                    } catch (err) {
                        detailError = "Could not parse match details";
                    }
                    detailLoading = false;
                } else if (xhr.status !== 0) {
                    handleMatchError("Could not load match details (" + xhr.status + ")");
                }
            }
        };
        xhr.send();
    }

    function loadTable(leagueId) {
        var id = String(leagueId || tableLeagueId || preferredTableLeagueId || "");
        if (!id) return;
        tableLeagueId = id;
        tableLoading = true;
        tableError = "";

        var url = Model.leagueUrl(id);
        var xhr = new XMLHttpRequest();
        xhr.timeout = 10000;
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", Model.USER_AGENT);
        xhr.setRequestHeader("Accept", "application/json");

        function handleTableError(msg) {
            tableError = msg;
            tableLoading = false;
        }

        xhr.ontimeout = function() {
            handleTableError("Standings request timed out");
        };

        xhr.onerror = function() {
            handleTableError("Network error loading standings");
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var parsed = Model.parseTable(xhr.responseText);
                        if (parsed.ok) {
                            table = parsed;
                            tableError = "";
                        } else {
                            tableError = parsed.error || "Could not read standings";
                        }
                    } catch (err) {
                        tableError = "Could not parse standings";
                    }
                    tableLoading = false;
                } else if (xhr.status !== 0) {
                    handleTableError("Could not load table (" + xhr.status + ")");
                }
            }
        };
        xhr.send();
    }

    function requestSearch(term) {
        searchQuery = String(term || "");
        if (searchQuery.trim().length < 2) {
            searchResults = [];
            searchLoading = false;
            searchDebounce.stop();
            return;
        }
        searchDebounce.restart();
    }

    function requestLeagueSearch(term) {
        leagueSearchQuery = String(term || "");
        if (leagueSearchQuery.trim().length < 2) {
            leagueSearchResults = [];
            leagueSearchLoading = false;
            leagueSearchDebounce.stop();
            return;
        }
        leagueSearchDebounce.restart();
    }

    function runLeagueSearch() {
        var term = String(leagueSearchQuery || "").trim();
        if (term.length < 2) {
            leagueSearchResults = [];
            leagueSearchLoading = false;
            return;
        }
        leagueSearchLoading = true;

        var xhr = new XMLHttpRequest();
        xhr.timeout = 8000;
        xhr.open("GET", Model.searchUrl(term));
        xhr.setRequestHeader("User-Agent", Model.USER_AGENT);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.ontimeout = function() {
            leagueSearchResults = [];
            leagueSearchLoading = false;
        };
        xhr.onerror = function() {
            leagueSearchResults = [];
            leagueSearchLoading = false;
        };
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                leagueSearchLoading = false;
                leagueSearchResults = xhr.status === 200 ? Model.parseLeagueSearch(xhr.responseText) : [];
            }
        };
        xhr.send();
    }

    function runSearch() {
        var term = String(searchQuery || "").trim();
        if (term.length < 2) {
            searchResults = [];
            searchLoading = false;
            return;
        }
        searchLoading = true;

        var url = Model.searchUrl(term);
        var xhr = new XMLHttpRequest();
        xhr.timeout = 8000;
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", Model.USER_AGENT);
        xhr.setRequestHeader("Accept", "application/json");

        xhr.ontimeout = function() {
            searchResults = [];
            searchLoading = false;
        };

        xhr.onerror = function() {
            searchResults = [];
            searchLoading = false;
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                searchLoading = false;
                if (xhr.status === 200) {
                    try {
                        searchResults = Model.parseSearch(xhr.responseText);
                    } catch (err) {
                        searchResults = [];
                    }
                } else {
                    searchResults = [];
                }
            }
        };
        xhr.send();
    }

    function noteGoal(event) {
        if (!event) return;
        var flags = {};
        for (var key in goalFlashIds) flags[key] = goalFlashIds[key];
        flags[String(event.matchId)] = Date.now();
        goalFlashIds = flags;
        goalFlashTimer.start();
        goalScored(event);
    }

    function demoGoal() {
        var matches = Model.flattenMatches(visibleLeagues);
        var event = Model.demoGoalEvent(matches.length ? matches[0] : null);
        if (event) noteGoal(event);
    }

    function demoWhistle() {
        var matches = Model.flattenMatches(visibleLeagues);
        var event = Model.demoFullTimeEvent(matches.length ? matches[0] : null, followedTeams);
        if (event) matchEnded(event);
    }

    function sendToast(headline, description) {
        var cleanHeadline = Model.notificationText(headline);
        var cleanDesc = Model.notificationText(description);
        var cmd = "notify-send -a 'Kickoff' -i 'trophy-symbolic' '" + cleanHeadline.replace(/'/g, "'\\''") + "' '" + cleanDesc.replace(/'/g, "'\\''") + "'";
        runner.connectSource(cmd);
    }

    function openMatchInBrowser(matchId) {
        var url = Model.matchPageUrl(matchId);
        Qt.openUrlExternally(url);
    }

    Timer {
        id: searchDebounce
        interval: 300
        onTriggered: root.runSearch()
    }

    Timer {
        id: leagueSearchDebounce
        interval: 300
        onTriggered: root.runLeagueSearch()
    }

    Timer {
        id: goalFlashTimer
        interval: 5000
        repeat: true
        onTriggered: {
            var now = Date.now();
            var next = {};
            var any = false;
            for (var key in root.goalFlashIds) {
                if (now - Number(root.goalFlashIds[key]) < 30000) {
                    next[key] = root.goalFlashIds[key];
                    any = true;
                }
            }
            root.goalFlashIds = next;
            if (!any) stop();
        }
    }

    // Polling timer
    Timer {
        interval: root.pollMs
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            root.todayKey = Model.dateKeyFromDate(new Date());
            if (root.dateKey === root.todayKey || root.liveCount === 0) {
                root.refreshMatches();
            }
        }
    }

    // Midnight rollover timer
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            var today = Model.dateKeyFromDate(new Date());
            if (root.todayKey === today) return;
            var wasToday = root.dateKey === root.todayKey;
            root.todayKey = today;
            if (wasToday) root.setDateKey(today);
        }
    }

    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
        }
    }

    Timer {
        id: startupTimer
        interval: 1200
        repeat: false
        running: false
        onTriggered: root.refreshMatches()
    }

    Component.onCompleted: {
        loadFollowedTeams();
        loadSelectedLeagues();
        startupTimer.start();
    }

    Connections {
        target: plasmoid.configuration
        function onFollowedTeamsChanged() {
            root.loadFollowedTeams();
        }
        function onSelectedLeaguesChanged() {
            root.loadSelectedLeagues();
        }
    }
}
