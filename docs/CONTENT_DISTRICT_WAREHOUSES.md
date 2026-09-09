# Content Handoff — District `warehouses` (district 8)

Task: district-level content per GDD §4.1 canon order (… → police → **warehouses**).
Name verified directly against `docs/GDD.md` §4.1 and `data/districts/district_warehouses.tres`.
Scope respected: only `content/**`, `assets/textures/**`, `assets/audio/**` (header
verify + spec only) and `docs/**`. No `*.gd`, `*.tscn`, `*.tres`, `tools/`, `locales/`,
`data/`, root `*.md`. Frozen docs untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/warehouses/lore_notes.json` | 8 notes (4 documents, 2 photos, 2 audio logs), stage-gated 0–3, `world_refs` ids |
| `content/districts/warehouses/item_spawns.json` | 4 stage tables + 10 fixed spawns + 8 container modifiers + rules R1–R8 |
| `content/districts/warehouses/prop_manifest.md` | 9-zone placement plan, stage-state table, art/audio gaps |
| `docs/CONTENT_DISTRICT_WAREHOUSES.md` | this handoff |

Also in this PR: warehouses asset pass (2 lit tile twins + a dark-floor edge repair,
ledgered in `docs/ASSET_LICENSES.md`), the `warehouses_lit.ogg` full spec appended to
`docs/AUDIO_COVERAGE.md` (G2g), and the district-8 row in `docs/CONTENT_PIPELINE_AUDIT.md`.

## Canon anchors used (verified in-repo, 2026-09-09)

- Prereq: `powered_by = [&"hospital"]` (`data/districts/district_warehouses.tres`) —
  the linear chain order in GDD §4.1 reads `police → warehouses`, but warehouses
  actually needs **hospital** FULL, not police. `map_position = (420, 180)`.
- **Not a leaf:** `industrial.powered_by = [&"warehouses", &"police"]` — the D8/D9
  convergence. Content is written so industrial can assume warehouses FULL later.
- Enemies: `crawler`, `destroyer`, `hunter` (`enemy_pool.gd`) — **crawler leads**: 1.5×
  speed, 6 m sight, light flinch 1 s (GDD §6.2). The district's lesson is *light as a
  disengage tool, never a weapon* (R5); the destroyer (no light reaction) holds the cold
  annex dead-end, and no chain spawn sits in its room.
- Themed loot: `district_loot.gd` BY_DISTRICT `warehouses = cable, fuse, scrap` → the
  depot-as-parts-store theme the notes lean on (`warehouses_note_03`/`_08` count drums
  12–18), mirrored in the tables and `warehouses_fix_stores_01`/`_02`.
- **Has blueprint:** `BLUEPRINTS[warehouses] = blueprint_backpack_slots` → R7 +
  `warehouses_fix_blueprint_01` (D8 schematic, fixed spawn in the office locker,
  DARK-reachable).
- Story doc: `doc_foreman_note` ("the conveyor thinks it is the foreman… 20 years") →
  extended, never copied, by `warehouses_note_04` (the notebook the note grew from) and
  `warehouses_note_06` (the storage request he routed to quarantine).
- Puzzle: `puzzle_system.gd` `switch_warehouses` (reward 150 coins, `power_stage` 2) →
  the pad in `z_switch_room` (feeder room, GG cell).
- GDD §9 lists a "portable workbench" at "D8 магазин". The district label predates the
  §4.1 rename (warehouses is D8 per the chain order), and there is **no**
  `blueprint_portable_workbench` id in `data/items/*.tres` — same treatment as police's
  D7 strobe: location flavour only, no invented item. Warehouses' real D8 schematic is
  `blueprint_backpack_slots` (`district_loot.gd` BLUEPRINTS canon).
- Ambience details exist, header-verified this pass:
  `warehouses_cargo_impact` (0.0), `warehouses_chain_rattle` (2.1),
  `warehouses_forklift_distant` (0.0), `warehouses_metal_creak` (0.0) — all
  1 ch/44.1 kHz/30.000 s; bed `warehouses_dark.ogg` 1 ch/44.1 kHz/36.000 s / 197,976 B.
  Lit bed is a **real gap** — full spec in AUDIO_COVERAGE G2g (spec only, not fabricated).
- Music: `music_manager.gd` maps warehouses → `harbor.wav`. `district_themes.gd`
  warehouses row is colour-only (no `"music"` key — same class as police; no mismatch
  to flag).
- Theme accent `#e85d3a` is hotter than the ember token (STYLE_GUIDE §2); manifest
  keeps it off surfaces (small emissives only, like police's `#5d5dc8` handling).
  Weather is **fog** — the yard reads through fog at every stage.

### world_refs reachability (computed `powered_by` closure)

`warehouses` needs hospital FULL; hospital needs residential FULL; residential needs
suburbs FULL (GDD §4.3: every prereq at FULL). So at arrival the player has completed
**suburbs, residential and hospital at every stage** — every suburbs-, residential- and
hospital-gated world id is safe here regardless of its own `min_stage`.

**Guaranteed history at arrival: suburbs + residential + hospital only.**

This pack therefore uses the Marat/grid-crew set, the meter-anomaly set (Superintendent,
news_meter_anomaly), Manya's lamp line, and — at `min_stage >= 2` only — the Act II
Project Architect set (`char_architect`, `faction_project_architect`,
`hist_project_architect`, `news_architect_denied`). The Architect ids are hospital-gated
and hospital is a *required* prerequisite, so they are guaranteed revealed at arrival;
notes 06/07 still hold them to STREETS+ for the district's own pacing.

**Not referenced:** park-gated ids (`char_keeper`, `faction_keepers`, `char_petrov`,
`char_radio_voice`, `hist_grid_built`, `hist_trees_complaint`, `hist_crew_walk_park`,
`hist_keeper_reversal`, `hist_radio_call`, `radio_01_power_station`, `diary_keeper_*`,
`news_trees_listen`), school/gas_station/police branch content, and all Act III ids
(`radio_02_grid_crew_relay`, `radio_03_keeper_reversal`). 15 world_refs, all resolving
inside the closure above.

Consistency: zone ids shared across all three files; item ids ⊆ `data/items` (41); note
ids and fixed-spawn ids globally unique; referenced prop scenes and audio files exist
(spec-only `warehouses_lit.ogg` exempted); new textures ship in this PR.

## For CODE agent (wiring checklist)

1. `scenes/districts/warehouses.tscn` already exists with the sibling node contract —
   populate 9 zones per `prop_manifest.md`; `props/examine.tscn` ×8;
   `props/puzzle_3d.tscn` on the feeder pad wired to `PowerSwitch`
   (`switch_warehouses`); usable `props/streetlight_3d.tscn` ×10 across dock gate/yard/
   halls/office/break room. **Never** place a lamp in `z_cold_storage` or
   `z_returns_cage` (stays unlit at every stage — R8, same class as police cells).
2. Loot rolls keyed by `DistrictData.Stage`; enforce R1 (chain solvable in DARK: 3
   cable / 2 fuse / 2 transistor + cage key, no lockpick), R2 (fuse/transistor never in
   DARK rolls; molotov from PARTIAL, noise_bomb from STREETS), R6 (scripted caches never
   empty), R7 (**blueprint_backpack_slots is a fixed spawn**, never a roll).
3. Lock `z_returns_cage` with `warehouses_fix_key_01` (foreman's desk drawer, unlocked).
4. Lore notes → existing pickup flow; add the `warehouses` id list to
   `DistrictLoot.LORE_DOCS`: `warehouses_note_01` … `warehouses_note_08`.
5. Crawler-led patrol: crawlers in the west/east halls, hunter in the yard, destroyer in
   the cold annex. The destroyer must not flee light; crawlers should break pursuit 1 s
   in the cone (light flinch per GDD §6.2), not burn.
6. New textures available: `tiles/warehouses_floor_lit.png` / `warehouses_wall_lit.png`;
   `tiles/warehouses_floor.png` was edge-repaired (3 px dark frame removed) — both follow
   the shipped `_lit` convention for `district_grading.gd::_apply_ground`.

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE runs them. This pass validated statically: JSON
parse, id cross-refs, path existence, Ogg header parse, image metrics.)

## For LOCALE agent — add to all 13 locales

`LORE_WAREHOUSES_<NN>_TITLE` / `LORE_WAREHOUSES_<NN>_TEXT`, NN ∈ 01–08 → **16 keys**;
en source = the `en` fields in `content/districts/warehouses/lore_notes.json`.

```
LORE_WAREHOUSES_01_TITLE  LORE_WAREHOUSES_01_TEXT
LORE_WAREHOUSES_02_TITLE  LORE_WAREHOUSES_02_TEXT
LORE_WAREHOUSES_03_TITLE  LORE_WAREHOUSES_03_TEXT
LORE_WAREHOUSES_04_TITLE  LORE_WAREHOUSES_04_TEXT
LORE_WAREHOUSES_05_TITLE  LORE_WAREHOUSES_05_TEXT
LORE_WAREHOUSES_06_TITLE  LORE_WAREHOUSES_06_TEXT
LORE_WAREHOUSES_07_TITLE  LORE_WAREHOUSES_07_TEXT
LORE_WAREHOUSES_08_TITLE  LORE_WAREHOUSES_08_TEXT
```

## Remaining districts

`industrial → substation → power_station`.
