# Difficulty intent (Session 28, D1)

What the game is meant to feel like at each difficulty, the rules that make "hard" fair, and the checks that hold each rule. The canon is `docs/GDD.md` (written in Russian; the sections cited
below are the ones read): 3 (flashlight, battery), 4 (power grid and its stages), 5.3 and 5.4 (the hit cap, the mercy time, death, respawn, Hardcore), 6 (the enemy roster and the Architect),
7 (stealth and noise), 8 (economy), 12.5 (New Game+), 14 (settings). The old curve model is `docs/DIFFICULTY_CURVE.md`; this file adds the intent above it and the rules below it.

## 1. The intent

- **Normal is tense and teaches.** A district is dark and full of things that hear and see (GDD 7); the light is the weapon and the only refuge (GDD 3, 6.2); a death comes from a cause the
  player could read: a monster they saw or heard coming, a flashlight they let run down, a route they chose. The damage cap of one hit (12 of 100 HP) and the 0.8 s mercy time after it
  (GDD 5.3) make a fight lose slowly, so a death is the end of several mistakes and not of one.
- **Hard is demanding and has no cheap shots.** It asks for more of the same skills: a hit costs 15 and not 12, a monster has 30 % more hit points and searches 30 % longer, a district
  has no spare repair part and a death has no ad revive. It does not ask for a new skill and it does not hide anything: every attack of every monster is announced the same way as on Normal.
- **Easy forgives** (hit points x1.5, monster damage x0.75, hit points of monsters x0.7, a noticing time of 0.5 s before a chase, spare parts, revive). It is for a player who wants the story.
- **The curve rises with the player's tools** (`docs/DIFFICULTY_CURVE.md`): the pistol at the second district, the rifle at the seventh, the shotgun at the eighth, twice the ammo from the sixth (the gas station, where the first two Hunters stand),
  and a district is calmer as it is restored (the monsters of a district are 6, 5, 4 and 3 at DARK, PARTIAL, STREETS and FULL).
- **A retry loses time and nothing else** (GDD 5.4): the run is loaded from the save, the player stands at the district entry with 50 % HP and the battery they died with (25 at the least); Hardcore (a choice
  made before the run, GDD 5.4) is the one place where a death deletes the save, and it says so.

## 2. The rules (each one has a check)

| # | Rule | Check | Held by |
|---|---|---|---|
| R1 | Every attack that can damage the player starts with a cue the player can see and hear, 0.35 s or more before the damage lands (0.4 s of game time from `MonsterTelegraph`; the windups of the Crawler, the Hunter and the Brute are 0.5 and 1.0 s with the same cue; the engine check reads the wall clock and takes 300 ms as its floor, CORRECTION_LOG 296) | TEL1 (engine) and `tools/qa_sim/telegraph_audit.py` (static) | `scripts/enemies/` |
| R2 | A hit costs at most 12 HP on Easy and Normal and 15 on Hard; the mercy time is 0.8 s; the sum of any number of monsters is at most 15 HP a second on Normal | DIF1 (engine), `tools/qa_sim/balance_sim.py` section 8 | `scripts/player/player_3d.gd`, `scripts/systems/settings_manager.gd` |
| R3 | Hard is harder than Normal by a measure, and Easy easier: the damage a player takes in one district fight, the hit points to chew through, the hits to die, the length of a search | `tools/qa_sim/balance_sim.py` section 8 (the model) and the bot's metric line at difficulty 2 (`QA_DIFFICULTY`) | `settings_manager.gd` `DIFFICULTY_PRESETS` |
| R4 | A monster is not waiting at the arrival point: every spawn point is 12 m or more from where the player arrives, and every spawn point has a refuge (a streetlight pole or a hiding spot) within 20 m (the poles give light from PARTIAL; at DARK the refuge is the flashlight, GDD 3 and 6.2) | ESC1 (engine) | `scripts/enemies/enemy_pool.gd`, the district scenes |
| R5 | No step of the curve above x1.6 without a new tool (a weapon or more ammo) | `tools/qa_sim/difficulty_curve.py` (static gate) | `ROSTER_BY_DISTRICT` |
| R6 | Nothing is a dead end: a district can be restored from its own loot with a margin of 20 %, the flashlight lasts the traversal, a respawn never leaves the player in the dark with no battery | `tools/qa_sim/balance_sim.py` sections 1 to 4, RET1 (engine) | `district_loot.gd`, `game_manager.gd` |
| R7 | Every number a New Game+ level or modifier stores is read by the game (the enemy damage bonus of a level also scales the hit cap of R2) | `tools/qa_sim/ngplus_table.py` (static gate), DIF1 (engine) | `new_game_plus.gd` and its readers |

## 3. What a human has to decide

The sum of these rules is not a playtest: how hard the gas station feels, how long a retreat to a lamp takes at a real pace, and whether Hard is fun are owner row D-1 (`docs/DIFFICULTY_CURVE.md`
section 5). The measures above are the ones a machine can hold.

## 4. Results

The numbers behind the rules, from the runs of Session 28 (`docs/RUN_STATE.md`). The model is a script and the bot is a machine that plays the whole game with simulated input and better than a first-time
player, so none of this is a playtest (section 3).

**By the numbers** (`python tools/qa_sim/balance_sim.py`, section 8: R2 and R3):

| | Easy | Normal | Hard |
|---|---|---|---|
| the most one hit takes (HP) | 12.0 | 12.0 | 15.0 |
| sustained damage (HP a second, with the 0.8 s mercy time) | 10.0 | 15.0 | 18.8 |
| hits to kill a player: the Architect | 12.5 | 8.3 | 6.7 |
| hits to kill a player: the Rotter | 20.0 | 10.0 | 8.0 |
| monster hit points (x) | 0.70 | 1.00 | 1.30 |
| the search of a monster (s) | 7.0 | 10.0 | 13.0 |
| spare repair parts per district | 1 | 0 | 0 |
| ad revive offered | yes | yes | no |

**By the engine** (`CLOSEOUT_ONLY=s28`): launch 1 (`s28_d1a_17f7304`) held 10 of 13 and failed TEL1, TEL3 and TEL7 on the set-up of the checks (a monster switched off in the far corner, the tween credited the frame it
starts in, the Shadow's sight); launch 2 (`s28_d1b_87f2e09`) held 16 of 17 and failed TEL3 by 2 ms against a floor of 350 ms (348 ms was read), which CORRECTION_LOG 296 records. The floor of the wall-clock measure is 300 ms
since, and the cue is asserted at 0.4 s of game time; the next battery re-reads it.

**By the bot** (`tools/qa_sim/autoplay_bot`, 3 seeds a difficulty; a hit is one `player_damaged` signal, "lost" the sum of their amounts after the cap and the difficulty, a death one `game_over`):

| Launch | Difficulty | Won | Deaths | Hits taken | Health lost | Items used | Wall time |
|---|---|---|---|---|---|---|---|
| 1, before the wake radius and the boss phases | Normal | 3 of 3 | 0, 0, 0 | 15, 16, 16 | 180, 192, 192 (mean 188) | 6, 6, 5 | 464, 459, 390 s |
| 1 | Hard | 2 of 3 | 1, 1, 0 | 21, 19, 9 | 315, 285, 135 (mean 245) | 7, 7, 5 | 494, 496, 527 s |
| 2, after them | Normal | 3 of 3 | 0, 0, 0 | 19, 21, 19 | 228, 252, 228 (mean 236) | 7, 6, 6 | 512, 428, 444 s |
| 2 | Hard | 2 of 3 | 0, 2, 1 | 9, 23, 19 | 135, 345, 285 (mean 255) | 5, 6, 7 | 516, 454, 498 s |

Read as it is: Normal stays winnable (the IRON RULE asks for one win in three at the default difficulty and the bot wins three in both launches, with no death and no softlock), and it costs the bot 26 % more health
after the heavy kinds stopped sleeping behind the player and the Architect's second and third phases began to swing (188 to 236): the pressure rose and nothing broke. Hard costs more than Normal by every measure the
bot has: lives (3 lost in launch 2 and 2 in launch 1, all of them in the finale, the first at 442 to 494 s, against none at Normal), health per winning run (300 and 315 against 188 and 236), and time. The seed that did not
win never died: it ran out of the 240 s the bot gives itself against the Architect's 1040 hit points at Hard (seed 3 in launch 1, seed 1 in launch 2); the deadline is the bot's and not the game's. What a person feels at
Hard, and how long a retreat to a lamp takes at a real pace, is owner row D-1 and no number here answers it.
