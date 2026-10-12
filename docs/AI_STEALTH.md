# Stealth and AI (Session 23)

Canon: `docs/PRODUCTION_BIBLE.md` pillar 2, "noise and visibility, not a detection meter": stealth is a simulation, not a stat bar creeping up. Nothing below adds
a meter of awareness; the bars the player sees show the two quantities the monsters read.

## What the monsters already did (read, not changed)

Sight with a range, an angle and a peripheral cone, cut by the player's visibility and by a line-of-sight ray; hearing of every `noise_emitted` (a shot, a run,
a shout) inside its radius when the monster has not seen the player; a search of 10 s within 5 m of the last known point when the player hid or the monster
fled (GDD S04); the `cold_trail` skill shortening it; a call for help from hounds and hunters when they first see the player (15 m).

## Added

| Item | What it does | Where |
|---|---|---|
| Throwable distraction | The craftable consumable `noise_bomb` did nothing when used. It is thrown along the aim, pops at the first thing it hits or 2.5 s after the throw, and makes a noise of 24 m: every monster inside it that has not seen the player goes to look at the spot, and those beyond it stay. | `scripts/gameplay/noise_bomb.gd`, `player_3d.gd` (`_throw_noise_bomb`), check AI1 |
| Group alert | A monster that starts to chase calls the neighbours: 8 m for every monster except the boss, 15 m for hounds and hunters as before. A neighbour that already chases keeps chasing; one that has not seen the player goes to the caller's spot. | `base_monster.gd` (`ALERT_RANGE`, `_change_state`), check AI2 |
| Last known place | A monster that loses the chased player (the player leaves its detect area) searches the place the player was, 10 s within 5 m, as the GDD says; before, it went straight back to its patrol. | `base_monster.gd` (`_on_detect_body_exited`), check AI3 |
| Difficulty hooks | The search lasts 7 s on Easy, 10 on Normal, 13 on Hard (`DIFFICULTY_PRESETS` "search"); on Easy a monster stands 0.5 s noticing before it chases (`reaction_sec`: Normal and Hard 0, the boss never waits). | `settings_manager.gd`, `base_monster.gd`, check AI4 |
| Detection gradient | The Noise and Visibility bars glide to what the player's state asks for (0.15 of the bar per 0.1 s poll) and their colour shades continuously from green through brass to ember (the state of the player steps the values: crouch, stealth, walk, run, an overloaded pack). The monsters read the values as before; only the picture changed. | `hud_3d.gd` (`GLIDE_PER_TICK`, `_shade`), check AI5 |

## Decisions and limits

- The group alert and the search at the last place change Normal. Both follow the GDD (section 7 and S04), and both are covered by the IRON RULE: the 3-seed bot
  has to win at least once with no new softlock (results below).
- The throw and the alert use the existing noise channel (`EventBus.noise_emitted`), so `NoisePropagation` and the NG+ `hunter_hearing` modifier apply to them too.
- Not built: a monster that loses the player behind a wall while still inside its detect area still paths to the player's real position (it has no memory of
  the last seen point inside the area). A second memory in the chase state changes every encounter; it is listed in `docs/KNOWN_ISSUES.md`.
