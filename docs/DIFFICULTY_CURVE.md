# Difficulty curve (Session 23, PX1)

What can be measured without a human at the controls is the enemy side of the curve and the player's gains along the spine; what the player feels as hard needs a human, and
that part is an owner row (D-1). The enemy side is read from the sources by `python tools/qa_sim/difficulty_curve.py` (a static gate of `tools/check.sh --static`).

## 1. The model

A district spawns `base + bonus(stage)` monsters: `MIN_ENEMIES_PER_DISTRICT` is 3 (`scripts/enemies/enemy_pool.gd:11`) and `_target_count` (line 94) adds 3 at DARK, 2 at PARTIAL,
1 at STREETS and nothing at FULL, so 6, 5, 4 and 3: a district is calmer as it is restored (the code says so: "the darker, the more monsters"). The kinds are taken in turn
from the district's roster (`ROSTER_BY_DISTRICT`, line 27). The strength of a monster is its hit points times its melee damage, from `data/monsters/monster_*.tres` (a fight
of equal rates is decided by that product: the square law of Lanchester), and the strength of a district at a stage is the sum over the monsters it holds, in thousands.
This is a model with one stated assumption (equal attack rates); it ranks districts and finds steps, it does not predict a death.

## 2. The curve (the tool's output)

| District | Roster | DARK | PARTIAL | STREETS | FULL | DARK step | Weapon found | Ammo (rounds per district) |
|---|---|---|---|---|---|---|---|---|
| suburbs | shadow, shadow, crawler | 3.8 | 2.8 | 2.4 | 1.9 | - | - | 0 |
| residential | shadow, crawler, crawler, rotter | 5.3 | 4.3 | 3.9 | 2.5 | x1.39 | pistol | 12 |
| park | shadow, crawler, hunter, hound, rotter | 8.2 | 7.8 | 6.4 | 5.7 | x1.55 | - | 12 |
| school | shadow, crawler, watcher, sharpshooter | 6.9 | 5.9 | 5.4 | 2.4 | x0.83 | - | 12 |
| hospital | watcher, shadow, crawler, rotter, rotter | 6.2 | 5.2 | 3.8 | 2.4 | x0.90 | - | 12 |
| gas_station | hunter, shadow, crawler, burner, hound | 11.9 | 7.7 | 7.0 | 5.7 | x1.93 | - | 24 |
| police | watcher, hunter, destroyer, sharpshooter, brute | 24.6 | 23.7 | 13.2 | 10.2 | x2.07 | rifle | 24 |
| warehouses | crawler, destroyer, hunter, brute, hound | 22.4 | 21.4 | 20.7 | 10.2 | x0.91 | shotgun | 24 |
| industrial | destroyer, hunter, watcher, brute, burner | 27.0 | 22.0 | 20.7 | 10.2 | x1.20 | - | 24 |
| substation | destroyer, watcher, hunter, sharpshooter, burner | 19.5 | 14.5 | 13.2 | 10.2 | x0.72 | - | 24 |
| power_station | destroyer, destroyer, watcher, brute, sharpshooter, burner | 25.8 | 24.5 | 21.5 | 11.0 | x1.32 | - | 24 |

The weapons are `WEAPON_FINDS` (`scripts/world/district_loot.gd:423`) and the ammo is `AMMO_PER_PICKUP` rounds (line 431) a pickup, none in the first district, one from the second,
two from the sixth, the gas station (`AMMO_DOUBLE_FROM`, line 398, counts from 0: "the guns come late"; it was the seventh until Session 28).

## 3. Reading it

- **No district is harder when it is restored**: every row falls from DARK to FULL (the gate fails on a row that rises). The player is rewarded for every stage.
- **The curve rises about sevenfold** from 3.8 (suburbs) to 25 to 27 (police onward), in three plateaus: the first five districts (3.8 to 8.2), the gas station (11.9), and
  the last five (19.5 to 27.0). The player's tools rise with it: the pistol at the second district, the rifle at the seventh, the shotgun at the eighth, and twice the ammo from
  the sixth.
- **The step to the police is x2.07, the sharpest, and it is paid for**: the district puts the first heavy kinds together (a brute and a destroyer with a sharpshooter) and it
  is where the rifle lies and the ammo doubles. The gate allows a step up to x2.2.
- **The step to the gas station is x1.93 and is paid with ammo** (two hunters among six, and the ammo doubles there: Session 28 moved it from the police, so the rise has a new tool
  and the gate of rule R5, no step over x1.6 without one, holds). The park used to open with a hunter beside a crawler (x1.65 over the residential district); it opens with the shadow
  now (x1.55). The gas station is still the first place a playtest should look (D-1).
- **The first district is the lowest point of the curve on purpose**: no gun, no ammo, shadows that die to the flashlight (`light_vulnerable`, 25 damage a second against 30 hit
  points: `data/monsters/monster_shadow.tres:16-19`) and that flee a lit district. The light is the weapon the player learns first.

## 4. What the bot says (and does not)

The autoplay bot plays all eleven districts and the finale on seeds 1, 2 and 3 (`docs/PACING_AUDIT.md`): no death in any of the 11 districts, two in the finale on every seed
(both revived, and the game won). It is a route-follower that restores power by the quest and the parts, with nudges (7, 9 and 16 on the three seeds), so it proves that
the spine is winnable and that the finale is the one place that kills a player who does not dodge; it does not prove that a human finds the gas station easy.

## 5. Owner rows

- **D-1** the human read of the curve. Executable action: play the first six districts once, writing down where you died or ran out of battery; if the gas station kills more
  often than the police does, move one hunter of its roster (`ROSTER_BY_DISTRICT`, `&"gas_station"`) to the hospital (a one-word change) and run `python tools/qa_sim/difficulty_curve.py`.
- **D-2** the player side: skill points, armor and the blueprints also rise with the spine (`docs/GDD.md`); the tool counts the weapons and the ammo only.
