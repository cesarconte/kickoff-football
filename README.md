# Kickoff Football

Live football scores, league tables, match events and goal notifications — directly in your
KDE Plasma 6 panel.

Kickoff shows a compact live summary in the panel and expands into a full popup with today's
fixtures, the matches of the clubs you follow and the standings of the competitions you selected.

> Ported and adapted from [omarchy-kickoff-plugin](https://github.com/atsokolas/omarchy-kickoff-plugin)
> by [atsokolas](https://github.com/atsokolas), originally built for the Omarchy bar.

## Features

- **Panel summary** — a theme-aware football icon plus a live counter, the scoreline and the
  match clock of a followed club that is currently playing.
- **Goal celebration** — the ball spins and a `GOAL!` shout appears in the panel when your team
  scores.
- **Full popup** with three tabs:
  - **Matches** — every fixture of the selected competitions, grouped by competition and kept in
    the order you configured in Settings.
  - **Following** — fixtures of the clubs you follow, even outside the competitions you selected.
  - **Table** — league standings, with navigation between the selected competitions.
- **Match detail** — events, lineups and live statistics (possession, xG, shots, cards, …).
- **Day navigation** — browse previous and next days of fixtures.
- **Desktop notifications** — opt-in alert whenever a followed club scores.
- **Settings** — search for leagues and clubs, reorder the selected competitions, and toggle
  notifications.
- **Spanish and English** localization.

## Requirements

- KDE Plasma **6.0** or later
- Qt 6 / QML
- Internet access (match data is served by the [FotMob](https://www.fotmob.com) API)

## Installation

### From source

```bash
git clone https://github.com/cesarconte/kickoff-football.git
cp -r kickoff-football ~/.local/share/plasma/plasmoids/org.kde.plasma.kickoff-football
systemctl --user restart plasma-plasmashell.service
```

Then add the widget to your panel or desktop: right-click the panel → **Add Widgets…** →
search for **Kickoff**.

### For development

Symlink the working copy so changes are picked up immediately:

```bash
ln -s /path/to/kickoff-football \
  ~/.local/share/plasma/plasmoids/org.kde.plasma.kickoff-football
systemctl --user restart plasma-plasmashell.service
```

After any QML change, restart `plasmashell` so the panel picks it up:

```bash
systemctl --user restart plasma-plasmashell.service
```

## Usage

| Action | Result |
| --- | --- |
| Left click on the panel | Open / close the full popup |
| Middle click on the panel | Refresh the data immediately |
| Click a match | Open the match detail view (events, stats, lineups) |
| Click a team name | Open the match page in your browser |

## Configuration

Right-click the widget → **Configure Kickoff…**

- **Notifications** — enable or disable desktop alerts for goals by followed clubs.
- **Leagues** — search for a competition and add it to the list; use the arrows to reorder it.
- **Following** — search for a club and follow it to pin its matches and receive goal alerts.

Settings are stored in `~/.config/plasma-org.kde.plasma.desktop-appletsrc` under the
`org.kde.plasma.kickoff-football` group.

## Development

The business logic lives in `contents/ui/Model.js` as a plain, dependency-free CommonJS module, so
it can be unit tested with Node without a running Plasma session:

```bash
node --test tests/
```

The test suite covers the panel headline, live/followed detection, tooltip rendering, celebration
copy, league search, competition ordering and filtering.

Project layout:

```
contents/
  config/      configuration UI (KCM)
  locale/es/   Spanish translation (.po / .mo)
  ui/          QML representations and the data backend
tests/         Node unit tests for Model.js
```

Every CI run executes the unit tests on each push and pull request to `main`.

## Credits

- Original plugin: [atsokolas/omarchy-kickoff-plugin](https://github.com/atsokolas/omarchy-kickoff-plugin)
- Match data provided by [FotMob](https://www.fotmob.com)

## License

MIT
