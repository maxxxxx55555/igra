# Pacing audit (Session 23, PX1)

Two sources, and neither is a human. The autoplay bot (`tools/qa_sim/autoplay_bot`, three seeds at 1x, ledger row 98, `s23_bot_f43d446`) plays the whole spine with simulated
input and logs when each district reaches each power stage; `tools/qa_sim/balance_sim.py` estimates the time of a human from the sources. The bot is a route-follower that
knows where every part lies and reaches the map by its button, so its times are the **floor of the pacing**, not the pace of a player; the three seeds agree to within a
second on every district (the route is deterministic; the seeds change only the finale), so they are three readings of one run, not three players.

## 1. The bot's spine (seconds of game time, mean of three seeds)

| District | DARK to PARTIAL | PARTIAL to STREETS | STREETS to FULL | Hand-over to the next | Total (mean, least to most) |
|---|---|---|---|---|---|
| suburbs | 18.1 | 1.0 | 1.1 | 1.5 | 21.7 (21.6 to 21.7) |
| residential | 14.2 | 6.6 | 5.3 | 1.2 | 27.2 (27.2 to 27.3) |
| park | 7.8 | 4.2 | 15.0 | 1.2 | 28.2 (28.1 to 28.2) |
| school | 9.7 | 1.4 | 3.4 | 1.3 | 15.8 (15.8 to 15.9) |
| hospital | 9.0 | 1.0 | 17.0 | 1.2 | 28.3 (28.1 to 28.4) |
| gas_station | 11.6 | 6.1 | 3.5 | 1.3 | 22.5 (22.3 to 22.6) |
| police | 9.5 | 9.4 | 1.0 | 1.2 | 21.1 (21.0 to 21.1) |
| warehouses | 11.0 | 3.8 | 14.3 | 1.3 | 30.3 (30.2 to 30.5) |
| industrial | 10.8 | 1.1 | 2.1 | 1.2 | 15.2 (15.1 to 15.3) |
| substation | 14.5 | 9.4 | 2.3 | 1.2 | 27.4 (26.0 to 28.2) |
| power_station | 19.5 | 14.9 | 1.1 | - | 35.5 (35.3 to 35.6) |

The eleven districts take 273 s (all lit at 280.8, 278.1 and 280.0 s on the three seeds); the finale takes 187, 149 and 213 s and ends in a win after two deaths on each seed (the
revive lines at 457.3 and 465.8, 420.5 and 427.1, 480.9 and 489.8 s). Time to the first interactable 24.4 to 24.9 s, to the first district lit 26.5 to 27.0 s
(`onboarding` line of the bot's summary, `scripts/tools/_qa_autoplay_runner.gd:783`).

## 2. What it shows

- **The spine is even**: a district takes between 15 and 36 s for the bot, and the first stage (DARK to PARTIAL) is the longest in eight of the eleven; the last two districts
  (substation 14.5 + 9.4 s, power station 19.5 + 14.9 s) take longer to restore than the early ones (the log does not say why).
- **Three long stretches are one stage each**: STREETS to FULL in the park (15.0 s), the hospital (17.0 s) and the warehouses (14.3 s), where the third restoration took
  the longest to reach; they are the places to watch for a human's longest walk.
- **The finale is where the run is lost**: it is the only place the bot dies, and it takes about as long as the first six districts together. Both revives are used on each seed.
- **The pace to the first power is quick** (27 s): a human reads the onboarding and the tutorial first (`docs/FIRST_5_MINUTES.md`).

## 3. The pace of a human (a model, not a measurement)

`tools/qa_sim/balance_sim.py` section 6 takes 12 minutes per district for a careful stealth clear in the dark (the dark style) or 18 for one that works the partly lit
streets (the partial style), a 15-minute boss fight, 1.5 minutes of menu and travel per district, and a multiplier of 1.8 for a first play: an efficient lower bound of
**2.7 h** (dark style) or 3.8 h (partial style), a typical first play of **4.9 h** or 6.9 h, against the target of 3 to 6 h of the design. The dark style, the one the game's
tension is built on, is inside the target; the partial style runs past it, a soft finding the tool keeps visible and does not fail on (its own note).

## 4. Owner rows

- **P-1** the pace of a person. Executable action: play the first three districts with a stopwatch and write the minutes of each, and compare with the model's 12 to 18
  minutes a district (before its multiplier); a district that takes more than twice that is the one whose parts are too far apart or too hidden.
- **P-2** the finale length: the bot spends 149 to 213 s in the final night and dies twice; whether that is the right length for a human is a playtest question.
