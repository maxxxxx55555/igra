# Content Handoff — District `school` (district 4)

Task: district-level content per GDD canon order (suburbs → residential → park → **school**).
Scope respected: only `content/**`, `assets/textures/**` and `docs/**` touched. No `*.gd`,
`*.tscn`, `*.tres`, `tools/`, `locales/`, `data/`, `PLAN.md`. GDD / PRODUCTION_BIBLE /
HANDOFF untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/school/lore_notes.json` | 8 notes (4 documents, 2 photos, 2 audio logs), stage-gated 0–3, `world_refs` ids |
| `content/districts/school/item_spawns.json` | 4 stage tables + 9 fixed spawns + 9 container modifiers + rules R1–R7 |
| `content/districts/school/prop_manifest.md` | 9-zone placement plan, stage-state table, art/audio gaps |
| `docs/CONTENT_DISTRICT_SCHOOL.md` | this handoff |

Also in this PR: school asset pass (lit tile twins + locker/chalkboard surfaces, ledgered in
`docs/ASSET_LICENSES.md`) and the `school_lit.ogg` bed spec appended to
`docs/AUDIO_COVERAGE.md` (spec only — no fabricated binary audio).

## Canon anchors used (verified in-repo, 2026-09-08)

- Prereq: `powered_by = [&"residential"]` (`data/districts/district_school.tres`) — verified,
  **not** park. `map_position = Vector2(420, 60)`.
- **Flag for CODE (data, not mine to fix):** no district's `.tres` lists `school` in
  `powered_by`, so school is currently a *leaf* of the power graph (hospital unlocks from
  residential). GDD §4 lists `school → hospital` in chain order; the tres set implements a
  branch instead. Content is written leaf-safe: nothing in the school pack assumes park was
  visited, and the north exit is narrative only.
- Enemies: `shadow`, `crawler`, `watcher` (`enemy_pool.gd`). Light-discipline lesson comes
  from `watcher_3d.gd` (2 s flashlight stun → `_rage_active`, ×1.25 chase speed).
- Themed loot: `district_loot.gd` BY_DISTRICT `school = key/scrap/battery/paper` (mirrored in
  the tables and `school_fix_paper_01`).
- **No blueprint** in school (`district_loot.gd` BLUEPRINTS = residential/park/police/
  warehouses) → no blueprint fixed spawn; stated as rule R7.
- Story doc: `doc_school_incident` (`data/documents/documents_catalog.json`) — 300 students in
  the basement, the counting in the heating pipes → extended, never copied, by
  `school_note_01` / `school_note_06` / `school_note_07`.
- Evacuation canon: `doc_evacuation_order` (school yard, sheet two, 04:00, "bring no lights")
  → `school_note_04` + world ids `hist_evacuation_arena`, `news_arena_collection`.
- Puzzle: `puzzle_system.gd` `switch_school` (reward 100 coins, `power_stage` 2) → the
  boiler-room transformer pad in `z_boiler_room`.
- Quest: `quest_manager.gd` `q_explore_school` (zone id `school_zone`).
- Ambience details exist and are consumed (`district_atmosphere.gd`): `school_bell_echo`,
  `school_locker_slam` , `school_chalk_scratch`, `school_desk_scrape`; bed
  `ambience/districts/school_dark.ogg`; music `music/abandoned_hallways_alt.mp3`
  (`music_manager.gd`).
- **Minor inconsistency noticed (CODE's call):** `district_themes.gd` school row points
  `"music"` at `res://assets/audio/music/residential.wav`, while `music_manager.gd` maps
  school → `abandoned_hallways_alt.mp3`. Both files exist; no content change made.

### world_refs reachability rule (new, applies from this pack on)

School unlocks from residential FULL, so **park may be unvisited** when the player reads
these notes. All `world_refs` in this pack therefore resolve only to ids gated at
suburbs/* or residential/*: `hist_blackout_night`, `hist_evacuation_arena`,
`hist_present_day`, `news_arena_collection`, `char_marat`, `char_grid_crew_recorder`,
`faction_city_power`, `faction_grid_crew`, `faction_street_watch`. The Keeper appears in
`school_note_08` only as the unnamed "old man from the lamp office" — flavour, no id, no
journal unlock, no Act II fact (CONTENT_WORLD_BIBLE rule 3: the Architect reveal stays
gated at hospital STREETS).

Consistency: zone ids shared across all three files; item ids ⊆ `data/items` (41);
referenced prop scenes (`props/examine.tscn`, `props/puzzle_3d.tscn`,
`props/streetlight_3d.tscn`) and every referenced audio file exist on disk.

## For CODE agent (wiring checklist)

1. `scenes/districts/school.tscn` — 9 zones per `prop_manifest.md`; `props/examine.tscn` ×8
   (one per note); `props/puzzle_3d.tscn` on the boiler-room pad wired to `PowerSwitch`
   (`switch_school`); `props/streetlight_3d.tscn` ×6 usable + gate flicker.
2. Loot rolls keyed by `DistrictData.Stage`; enforce R1 (repair chain solvable in DARK with
   zero lockpicks), R4 (no firearms), R6 (shelter caches non-RNG), R7 (no blueprint).
3. Lock `z_basement_shelter` with `school_fix_key_01` (gym equipment bin, unlocked).
4. Lore notes → existing pickup flow; add the `school` id list to `DistrictLoot.LORE_DOCS`:
   `school_note_01` … `school_note_08`.
5. Light-discipline teaching: watcher patrol anchored to `z_corridor_lockers`; keep the
   locker recesses as the only cover so the note's advice is literally playable.
6. `z_basement_shelter` stays unlit at every stage (see stage table); don't let a global
   relight pass overwrite it.
7. Optional: `tiles/school_floor_lit.png` / `school_wall_lit.png` shipped in this PR follow
   the `suburbs|hospital|power_station` `_lit` convention for a stage-based ground swap
   (`district_grading.gd::_apply_ground`).

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE agent runs them. This pass validated statically:
JSON parse, id cross-refs, path existence.)

## For LOCALE agent — add to all 13 locales

`LORE_SCHOOL_<NN>_TITLE` / `LORE_SCHOOL_<NN>_TEXT`, NN ∈ 01–08 → **16 keys**; en source =
the `en` fields in `content/districts/school/lore_notes.json`.

```
LORE_SCHOOL_01_TITLE  LORE_SCHOOL_01_TEXT
LORE_SCHOOL_02_TITLE  LORE_SCHOOL_02_TEXT
LORE_SCHOOL_03_TITLE  LORE_SCHOOL_03_TEXT
LORE_SCHOOL_04_TITLE  LORE_SCHOOL_04_TEXT
LORE_SCHOOL_05_TITLE  LORE_SCHOOL_05_TEXT
LORE_SCHOOL_06_TITLE  LORE_SCHOOL_06_TEXT
LORE_SCHOOL_07_TITLE  LORE_SCHOOL_07_TEXT
LORE_SCHOOL_08_TITLE  LORE_SCHOOL_08_TEXT
```

## Remaining districts

`hospital → gas_station → police → warehouses → industrial → substation → power_station`.
