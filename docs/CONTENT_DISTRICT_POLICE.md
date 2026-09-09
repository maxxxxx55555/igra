# Content Handoff — District `police` (district 7)

Task: district-level content per GDD §4.1 canon order (… → gas_station → **police**).
Name verified directly against `docs/GDD.md` §4.1 and `data/districts/district_police.tres`.
Scope respected: only `content/**`, `assets/textures/**`, `assets/audio/**` (header
verify + spec only) and `docs/**`. No `*.gd`, `*.tscn`, `*.tres`, `tools/`, `locales/`,
`data/`, root `*.md`. Frozen docs untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/police/lore_notes.json` | 8 notes (4 documents, 2 photos, 2 audio logs), stage-gated 0–3, `world_refs` ids |
| `content/districts/police/item_spawns.json` | 4 stage tables + 10 fixed spawns + 8 container modifiers + rules R1–R8 |
| `content/districts/police/prop_manifest.md` | 9-zone placement plan, stage-state table, art/audio gaps |
| `docs/CONTENT_DISTRICT_POLICE.md` | this handoff |

Also in this PR: police asset pass (2 lit tile twins + cell-bar surface, ledgered in
`docs/ASSET_LICENSES.md`), the `police_lit.ogg` spec appended to
`docs/AUDIO_COVERAGE.md`, and the district-7 row in `docs/CONTENT_PIPELINE_AUDIT.md`.

## Canon anchors used (verified in-repo, 2026-09-08)

- Prereq: `powered_by = [&"park"]` (`data/districts/district_police.tres`) — **not**
  gas_station, despite the chain order in GDD §4.1 reading `gas_station → police`.
  `map_position = (300, 180)`.
- **Not a leaf:** `industrial.powered_by = [&"warehouses", &"police"]`. Content is
  written so industrial can assume police FULL later; nothing in this pack assumes
  hospital/school/gas_station were visited.
- Enemies: `watcher`, `hunter`, `destroyer` (`enemy_pool.gd`) — destroyer leads, so
  the light-discipline lesson school taught does **not** apply (destroyer "не реагирует"
  to light, GDD §6.2). The district's economy is cover and dead-ends (R5), not cones.
- Themed loot: `district_loot.gd` BY_DISTRICT `police = key, medkit, tool, gunpowder,
  case` → mirrored in the tables and in `police_fix_armory_01` / `_02` / `police_fix_key_01`
  / `police_fix_med_01`.
- **Has blueprint:** `BLUEPRINTS[police] = blueprint_backpack_capacity` → R7 +
  `police_fix_blueprint_01` (opposite of school/hospital/gas_station R8).
- Story doc: `doc_evacuation_order` (second list, 47 people, school yard 04:00) →
  extended, never copied, by `police_note_01` (the station's desk carbon).
- Puzzle: `puzzle_system.gd` `transformer_police` (reward 2 battery, `power_stage` 2)
  → the pad in `z_generator_room`.
- GDD §9 strobe workbench "D7 допросная": interrogation 2 is the location
  (`z_interrogation`, pulsing desk lamp). There is **no** strobe blueprint id in
  `data/items/*.tres`; flavour only, no invented item.
- Ambience details exist, header-verified this pass:
  `police_radio_static` (4.9), `police_siren_tail` (0.0), `police_boots_concrete` (2.4);
  bed `police_dark.ogg`. Lit bed is a **real gap** — spec only, see AUDIO_COVERAGE G2f.
- Music: `music_manager.gd` maps police → `downtown.wav` (same file as gas_station).
  `district_themes.gd` police row has no `"music"` key in the theme dict (colour-only
  row). No mismatch of the school/hospital class to flag.
- Theme accent `#5d5dc8` is over-saturated for surfaces (STYLE_GUIDE §2); manifest
  keeps it on the door LED and radio LED only.

### world_refs reachability (computed `powered_by` closure)

`police` needs park FULL, and park needs suburbs FULL (GDD §4.3: every prereq at FULL).
So at arrival the player has completed **suburbs and park at every stage** — every
suburbs- and park-gated world id is safe here regardless of its own `min_stage`.

**Guaranteed history at arrival: suburbs + park only.**

This pack therefore uses Keeper/radio material (`char_keeper`, `faction_keepers`,
`hist_keeper_reversal`, `char_radio_voice`, `radio_01_power_station`, `hist_radio_call`)
and the evacuation/grid-crew set from suburbs.

**Not referenced:** residential-gated ids (`char_babka_manya`, `char_superintendent`,
`diary_manya_01`, `news_meter_anomaly`) and hospital-gated Act II Architect ids
(`char_architect`, `faction_project_architect`, `hist_project_architect`,
`news_architect_denied`). The hospital branch may be untouched when the player
arrives. No Act III ids (`radio_02_grid_crew_relay`, `radio_03_keeper_reversal`).

Consistency: zone ids shared across all three files; item ids ⊆ `data/items` (41);
referenced prop scenes and audio files exist; the new textures ship in this PR.

## For CODE agent (wiring checklist)

1. `scenes/districts/police.tscn` — 9 zones per `prop_manifest.md`;
   `props/examine.tscn` ×8; `props/puzzle_3d.tscn` on the transformer pad wired to
   `PowerSwitch` (`transformer_police`); `props/streetlight_3d.tscn` ×5 usable.
   **Never** place a streetlight in `z_holding_cells` (stays unlit at every stage).
2. Loot rolls keyed by `DistrictData.Stage`; enforce R1 (chain solvable in DARK, no
   lockpick), R2 (molotovs from PARTIAL, noise_bomb from STREETS), R4 (no firearms),
   R6 (armory/evidence non-RNG), R7 (**blueprint_backpack_capacity is a fixed spawn**),
   R8 (no gunpowder on the generator pad or dispatch rack).
3. Lock `z_evidence_room` with `police_fix_key_01` (desk drawer, unlocked).
   `z_interrogation` stays unlocked so R7 holds in DARK.
4. Lore notes → existing pickup flow; add the `police` id list to
   `DistrictLoot.LORE_DOCS`: `police_note_01` … `police_note_08`.
5. Destroyer patrol anchored to the east wing (`z_holding_cells` → `z_evidence_room`);
   do not give it a light-flee behaviour — R5 is unplayable if the destroyer still
   burns in the cone.
6. New texture available: `surfaces/cell_bars_512.png`; lit tiles
   `tiles/police_floor_lit.png` / `_wall_lit.png` follow the shipped `_lit` convention
   for `district_grading.gd::_apply_ground`.

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE runs them. This pass validated statically: JSON
parse, id cross-refs, path existence, Ogg header parse, image metrics.)

## For LOCALE agent — add to all 13 locales

`LORE_POLICE_<NN>_TITLE` / `LORE_POLICE_<NN>_TEXT`, NN ∈ 01–08 → **16 keys**;
en source = the `en` fields in `content/districts/police/lore_notes.json`.

```
LORE_POLICE_01_TITLE  LORE_POLICE_01_TEXT
LORE_POLICE_02_TITLE  LORE_POLICE_02_TEXT
LORE_POLICE_03_TITLE  LORE_POLICE_03_TEXT
LORE_POLICE_04_TITLE  LORE_POLICE_04_TEXT
LORE_POLICE_05_TITLE  LORE_POLICE_05_TEXT
LORE_POLICE_06_TITLE  LORE_POLICE_06_TEXT
LORE_POLICE_07_TITLE  LORE_POLICE_07_TEXT
LORE_POLICE_08_TITLE  LORE_POLICE_08_TEXT
```

## Remaining districts

`warehouses → industrial → substation → power_station`.
