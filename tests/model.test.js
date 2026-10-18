const test = require("node:test");
const assert = require("node:assert/strict");
const Model = require("../contents/ui/Model.js");

function match(id, state, homeId, awayId) {
  return {
    id: String(id),
    state,
    timeTS: Number(id),
    utcTime: "2026-10-18T17:00:00Z",
    liveTimeShort: "64'",
    home: { id: String(homeId), name: "Home", score: 1 },
    away: { id: String(awayId), name: "Away", score: 0 }
  };
}

test("live count in the panel states that it counts live matches", () => {
  const result = Model.barHeadline([{
    matches: [match(1, "live", 11, 12), match(2, "live", 21, 22), match(3, "live", 31, 32)]
  }], []);

  assert.equal(result.text, "LIVE · 3 matches");
  assert.equal(result.count, 3);
  assert.equal(result.live, true);
});

test("live count follows tracked clubs when their matches are live", () => {
  const result = Model.barHeadline([{
    matches: [match(1, "live", 401657, 12), match(2, "live", 401657, 22), match(3, "live", 31, 32)]
  }], [{ id: "401657", name: "Barcelona (W)", leagueId: "9907", leagueName: "Liga F" }]);

  assert.equal(result.text, "LIVE · 2 matches");
  assert.equal(result.count, 2);
});

test("unfollowed live matches are counted when followed clubs are not playing", () => {
  const result = Model.barHeadline([{
    matches: [match(1, "live", 21, 22)]
  }], [{ id: "401657", name: "Barcelona (W)", leagueId: "9907", leagueName: "Liga F" }]);

  assert.equal(result.text, "LIVE · 1 match");
  assert.equal(result.count, 1);
});

test("goal celebration always uses the requested GOAL label", () => {
  for (const seed of [0, 1, 2, 3, 4, 5, 100]) {
    assert.equal(Model.celebrationLine({}, seed), "GOAL!");
  }
});

test("league search finds Liga F and following Barcelona (W) exposes its standings", () => {
  const search = Model.parseLeagueSearch(JSON.stringify([{
    title: { key: "all", value: "All" },
    suggestions: [{ type: "league", id: "9907", name: "Liga F", ccode: "ESP" }]
  }]));
  const choices = Model.competitionChoices([], [
    { id: "401657", name: "Barcelona (W)", leagueId: "9907", leagueName: "Liga F" }
  ]);

  assert.deepEqual(search, [{ id: "9907", name: "Liga F", ccode: "ESP" }]);
  assert.deepEqual(choices, [{ id: "9907", name: "Liga F", ccode: "" }]);
});

test("competition navigation wraps in either direction and recovers a missing selection", () => {
  const choices = [{ id: "47" }, { id: "9907" }, { id: "87" }];

  assert.equal(Model.adjacentCompetition(choices, "9907", 1).id, "87");
  assert.equal(Model.adjacentCompetition(choices, "9907", -1).id, "47");
  assert.equal(Model.adjacentCompetition(choices, "missing", 1).id, "47");
  assert.equal(Model.adjacentCompetition(choices, "missing", -1).id, "87");
  assert.equal(Model.adjacentCompetition([{ id: "47" }], "47", 1), null);
});
