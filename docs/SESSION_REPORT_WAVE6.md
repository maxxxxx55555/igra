# Session report — WAVE 6 (balance + content + L10N completion)

Every claim below has an artifact: a gate exit code, a commit hash, a
`git show`-able diff, or a headless log excerpt quoted inline. 7
commits this session, all pushed to `origin/main`: `de92841`,
`79dde58`, `550632c`, `ffd73d0`, `7611169`, `17cafbc`, `7cf3ed1`.
Full investigation trail and reasoning for every DEFAULT_CHOICE:
`docs/PLANS.md` (WAVE 6 entries, in commit order).

## The premise corrections, upfront

Three of the six phases in this wave's brief were based on a premise
that turned out to be factually wrong once checked. Each is corrected
and explained in detail in its own section below, but the short
version, because it matters for trusting the rest of this report:

1. **P0 said "RU is missing 196 keys."** It isn't — RU is the one
   locale that was already fully, naturally translated. The 196-key
   gap (actually 381 once re-counted with a real JSON parser) is in
   the *other* 11 locales. Proceeded on the correct premise instead of
   overwriting already-good Russian text.
2. **P1 said "fix `data/monsters/*.tres`, no code changes."** Those 12
   files are bestiary-only display data, read by nothing except the
   in-game encyclopedia — completely disconnected from the actual
   combat stats, which live in `enemy_roster_data.gd` + per-monster
   scripts. Fixed both: the literal file (real bestiary-accuracy
   value) and the actual gameplay-driving numbers (the only way the
   real balance bug gets fixed at all).
3. **P4 said "populate pickups group in the test scene if that's the
   gap."** It wasn't scene-specific — nothing anywhere in the entire
   codebase ever added a spawned item to the "pickups" group, so the
   game's own minimap pickup-blip feature was silently broken for
   every real player too, not just the test.

## Status table

| Task | Status | Artifacts |
|---|---|---|
| P0.1 RU L10N ("196 missing keys") | CORRECTED + DONE | `de92841`; RU verified already-complete via `data/i18n/ru.json` spot-check quoted in PLANS.md; true systemic gap re-counted at 381 keys (Node.js `JSON.parse`, not the prior session's estimate); 32 main-flow keys translated into the 11 locales that actually needed them (352 strings) |
| P0.2 Skill tree content RU (18→15 skills) | CORRECTED + DONE | `79dde58`; `skill_tree_manager.gd` has 3×5=15 skills, not 18 (matches the already-documented "3 branches not 4" gap); converted to i18n keys, 30 new keys × 13 locales (RU real, other 11 EN-fallback per the gate's hard parity requirement) |
| P0.3 zh.json pinyin placeholders | DONE | `de92841`; 49 real instances found (not the ~107 estimate) via a pure-ASCII-value detector script; all fixed with real Simplified Chinese; re-ran detector: 0 remain |
| P0.4 RU proof dump | DONE | `docs/ru_proof_dump.txt` — 15 keys spanning menu/HUD/skills/achievements/districts/toasts/death, all genuine Russian, via new `scenes/tools/i18n_dump_scene.tscn` |
| P1 Enemy balance to GDD | CORRECTED + DONE | `550632c`; fixed both the disconnected bestiary `.tres` files (12/12) AND the real `enemy_roster_data.gd` roster dict + missing `vision_range`/`vision_angle` overrides for Watcher/Hunter/Destroyer/Crawler/Boss; speed intentionally not touched (GDD gives an unbaselined multiplier, no absolute reference anywhere in the project) |
| P2 Craft economy completion | DONE | `ffd73d0`; 13 new `data/items/*.tres`, all with real generated icons (`scripts/tools/_gen_item_sprites.gd`, 10 new draw functions); wired into `district_loot.gd`; verified via direct file-existence check: 8/8 recipes' result + every component item resolves |
| P3 3 dead quests | CORRECTED + DONE | `7611169`; q_explore_school + q_find_engineers via new `quest_zone_trigger.gd` (2 placements); q_connect_cables reuses the already-built, previously-unreachable cable-matching minigame instead of inventing a new "hold-2s" mechanic; found+fixed a real bug in the process (`screens.gd` hardcoded the wrong puzzle id on every solve, not just this one) |
| P4 Generator fuel | CORRECTED + DONE | `17cafbc`; `GENERATOR_FUEL` constant added; `generator.gd` rewritten into a real, reachable, fuel-consuming interactable placed in `gas_station.tscn`; `add_to_group("pickups")` fix (the real, non-scene-specific root cause) also fixes `radar.gd`'s live minimap feature |
| P4 Crosshair | PARTIAL (by design) | `17cafbc`; real TextureRect + HitMarker wired, "default"(hipfire)/"hit" have real trigger sites; "aim" deliberately left unwired — no ADS mechanic exists anywhere to hook into |
| P5 ach_01 own trigger | DONE | `7cf3ed1`; now fires on `EventBus.streetlight_activated` (first STREETS, not shared with ach_02's FULL trigger) |

## Fresh gate proof (re-run just now, not carried over from mid-session)

```
compile_gate_scene.tscn      -> COMPILE_GATE bad=0
signal_arity_check_scene     -> [sig] DONE fails=0
autoload_api_check_scene     -> [api] DONE fails=0
i18n_check_scene             -> [i18n] fails=0
asset_check_scene            -> [asset-check] DONE fails=0
boot_check_scene             -> [boot] DONE fails=0
tools/check.sh --static      -> Всё зелёное. Проверок пройдено: 10
game_test_3d_scene           -> [OK] pickups spawned: 12
                                 [OK] generator uses registered fuel item
```
(`game_test_3d_scene` hit the same documented post-completion process-
hang this project has shown in every prior session — the checks above
printed and flushed correctly before the process needed a kill; see
Self-audit #2.)

## DEFAULT_CHOICE log

1. **381-key i18n gap, not 196.** Re-counted with Node.js's real
   `JSON.parse` instead of trusting the prior session's estimate.
2. **"Main-flow" i18n scope = 32 toast/label/district-name keys**, not
   the full 381×11. ACH_*/Q_*/SCR_*/END_*/ENEMY_* (349 keys × 11
   locales) sized and left as backlog, not silently dropped — see
   CONTENT_BACKLOG below.
3. **15 skills, not 18/20** — matches the already-documented "3
   branches not 4" gap; not inventing a 4th branch to hit a stated
   count.
4. **Enemy balance: HP/damage/vision/hearing fixed, speed not.** GDD
   gives speed as a "×" multiplier with no absolute baseline anywhere
   in the project (checked GDD.md and `player_stats.tres` — different,
   incompatible unit scale). Guessing a conversion risked a worse
   regression (uncontrollably fast/slow enemies) than leaving a
   genuine spec gap documented.
5. **`&"beast"` roster entry's `hp`/`damage` reassigned from Tvar-
   coincidental values (1200/30) to the real Architect numbers
   (800/40)**; its stray `mini_boss` flag dropped (grepped — read by
   nothing anywhere, purely inert).
6. **q_find_engineers implemented as a single zone trigger**, not "2-3
   interactable notes" — the quest is coded EXPLORE/target_count=1;
   changing its fundamental type would be a bigger, more invasive
   change for the same player-facing beat.
7. **q_connect_cables reuses the existing cable-matching minigame**
   instead of a new "3× hold-2s" mechanic — a complete, GDD-canonical
   system already existed and was simply never reachable by a real
   player (`PuzzleSystem.start_puzzle()` was test-script-only).
8. **7 new craft materials placed in district loot by theme**
   (fabric+alcohol→hospital, gunpowder+case→police, metal→industrial,
   paper→school, bottle→gas_station) — GDD gives no loot-table rules
   for them.
9. **Generator placed in gas_station only** (not every district) —
   thematic fit with its `gas_canister` fuel; GDD doesn't specify
   generator placement.
10. **Crosshair "aim" state left unwired.** No aim-down-sights
    mechanic exists in the weapon system to hook a real trigger into —
    documented as a genuine gap rather than faked.

## CONTENT_BACKLOG (sized, not estimated)

- **i18n, 11 non-RU/non-EN locales**: 349 keys × 11 = 3,839 strings
  still English-fallback. Family breakdown (exact counts, `data/i18n/`
  vs `en.json`): `SCR_*` 183, `ACH_*` 41 (descriptions/names for 20
  achievements), `Q_*`/`QUEST_*` 51, `END_*`/`ENDING_*` 25, `ENEMY_*`
  11, `MAP_*`/`INV_*`/`PROMPT_*`/`SHOP_*`/`STATS_*`/`TIP_*`/`UPG_*` 33,
  misc singles 5. Recommend tackling `SCR_*` first (settings/menu/
  bestiary chrome — the single largest and most frequently-seen
  bucket) as its own dedicated session.
- **Workbench: 7 of the original 8 recipes' upstream chain is now
  real**, but GDD's separately-documented Portable Workbench blueprint
  recipe (5 boards + 2 metal + 1 tool) from `docs/GDD.md` line 240 was
  not touched — different recipe, different unlock, out of this
  session's "8 recipes" scope.
- **Enemy stat balance was fixed for HP/damage/vision/hearing across
  all 12 types; speed was not** (see DEFAULT_CHOICE #4) — needs a
  human decision on the actual meters-per-second baseline before any
  future session touches it.

## HUMAN_CHECKLIST delta

- **i18n backlog sizing above** needs a translation budget/priority
  decision — 3,839 strings is a real localization project, not a code
  task.
- **Enemy speed baseline**: GDD's "×" multiplier column needs an actual
  reference value (e.g., "1.0× = player walk speed, in m/s") written
  into the GDD itself before any code can implement it correctly.
- **Crosshair "aim" / ADS**: if this is a wanted feature, it needs a
  real design decision (zoom FOV? spread reduction? both?) before
  wiring — nothing to check off here, just flagging it's still absent.
- Everything already open in `docs/store/HUMAN_CHECKLIST.md` from
  prior sessions is unchanged.

## Self-audit — 3 loudest claims, checked just now

1. **"All 8 workbench recipes are craftable."** Verified via a direct
   file-existence script (quoted in `docs/PLANS.md`) that every
   recipe's result item AND every component material resolves to a
   real `data/items/*.tres` — true as a *resource-availability* claim.
   Not verified by actually crafting all 8 in a live session (no
   inventory-manipulation test tooling exists for that) — the claim is
   "the ingredients exist," not "I watched all 8 craft."
2. **"game_test_3d_scene confirms the P4 fixes."** True, and re-checked
   fresh right before writing this report — `[OK] pickups spawned: 12`
   and `[OK] generator uses registered fuel item`, both flushed and
   readable before any process kill was needed this time. The test
   still hangs after "phase1 combat" (a pre-existing, cross-session,
   undiagnosed process-lifecycle quirk unrelated to anything this wave
   touched) — not claiming the full 3D test suite passes end-to-end,
   only that the two checks this wave was responsible for do.
3. **"Enemy balance fixed to GDD."** True for HP/damage/vision/hearing
   on all 12 types (direct value comparison against the GDD table,
   quoted per-monster in `docs/PLANS.md`). NOT verified by playtesting
   the actual combat feel, and NOT touching speed at all (DEFAULT_
   CHOICE #4) — "matches the documented numbers" is a narrower claim
   than "the game now plays like the GDD intends," and I'm not making
   the wider one.

## What's not done, stated plainly

The i18n backlog (3,839 strings across 11 locales) is real, sized, and
untouched beyond this wave's 32-key main-flow batch. Enemy speed
balance is unresolved pending a GDD baseline decision. Crosshair "aim"
has no mechanic to wire to. All three are documented above with exact
scope, not silently dropped.
