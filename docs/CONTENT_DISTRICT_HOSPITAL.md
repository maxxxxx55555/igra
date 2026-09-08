# Content Handoff — District `hospital` (district 5)

Task: district-level content per GDD §4.1 canon order (… → park → school → **hospital**).
Confirmed against `docs/GDD.md` §4.1: the 11-district chain contains **no `metro`**; the
district after `school` is `hospital`.
Scope respected: only `content/**`, `assets/textures/**` and `docs/**` touched. No `*.gd`,
`*.tscn`, `*.tres`, `tools/`, `locales/`, `data/`, root `*.md`. GDD / PRODUCTION_BIBLE /
HANDOFF untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/hospital/lore_notes.json` | 8 notes (4 documents, 2 photos, 2 audio logs), stage-gated 0–3, `world_refs` ids |
| `content/districts/hospital/item_spawns.json` | 4 stage tables + 10 fixed spawns + 9 container modifiers + rules R1–R8 |
| `content/districts/hospital/prop_manifest.md` | 10-zone placement plan, stage-state table, art/audio gaps |
| `docs/CONTENT_DISTRICT_HOSPITAL.md` | this handoff |

Also in this PR (shared with the `school` pass): hospital asset pass (3 prop surfaces,
ledgered in `docs/ASSET_LICENSES.md`) and the hospital audio audit appended to
`docs/AUDIO_COVERAGE.md` (hospital needs **no** lit bed — it already ships one).

## Canon anchors used (verified in-repo, 2026-09-08)

- Prereq: `powered_by = [&"residential"]` (`data/districts/district_hospital.tres`);
  hospital powers `warehouses` (`district_warehouses.tres`). `map_position = (60, 180)`.
- **Act II gate (the point of this district):** `char_architect`,
  `faction_project_architect`, `hist_project_architect`, `news_architect_denied` all reveal
  at `hospital / min_stage 2` per `content/world/*` + `docs/CONTENT_WORLD_BIBLE.md` rule 3.
  Notes `06`, `07`, `08` carry those ids and are gated at `min_stage >= 2`; notes `01`–`05`
  only hint ("the fourth feeder", "the draw"), never naming the project. Rule R7 in
  `item_spawns.json` restates this for the spawner.
- Enemies: `watcher`, `shadow`, `crawler` (`enemy_pool.gd`) — watcher leads, so the school's
  light-discipline lesson is assumed learned; hospital's axis is supply, not teaching.
- Themed loot: `district_loot.gd` BY_DISTRICT `hospital = medkit, medkit, serum, fabric,
  alcohol` → mirrored in the tables and in `hospital_fix_med_*` / `hospital_fix_craft_*`.
- **No blueprint** in hospital (BLUEPRINTS = residential/park/police/warehouses) → rule R8.
- Story doc: `doc_hospital_note` (patient N from substation Ж-3, "the light is a door",
  windowless ward, the lamp that flickered by itself) → extended, never copied, by
  `hospital_note_04` (continuation sheet) and echoed by `hospital_note_03`.
- Puzzle: `puzzle_system.gd` `generator_hospital` (reward 1 medkit, `power_stage` 2) → the
  diesel-plant pad in `z_generator_room`.
- Ambience details exist and are consumed (`district_atmosphere.gd`):
  `hospital_monitor_beep` (4.6), `hospital_gurney_wheels` (0.0), `hospital_pa_mumble` (2.4),
  `hospital_elevator_distant` (0.0); beds `hospital_dark.ogg` **and** `hospital_lit.ogg`
  both ship; music `abandoned_hallways_alt.mp3` (`music_manager.gd`).
- Theme accent is `#5dc8f4` — the only teal district. STYLE_GUIDE §2 reserves teal for
  information, which is what this district *is* (records, charts, the reveal); the manifest
  keeps the restored operating lamp teal-tinted rather than white.
- **Same data flag as the school pass:** `district_themes.gd` hospital row points `"music"`
  at `residential.wav` while `music_manager.gd` maps hospital → `abandoned_hallways_alt.mp3`.
  Both files exist; no content change made (CODE's call).

### world_refs reachability

Hospital unlocks from residential FULL, so park may be unvisited. Non-Architect refs stay
suburbs/residential-gated (`hist_blackout_night`, `hist_evacuation_arena`,
`news_arena_collection`, `char_marat`, `char_grid_crew_recorder`, `faction_grid_crew`,
`faction_street_watch`); the four hospital-gated Architect ids appear only in notes with
`min_stage >= 2`, i.e. exactly at their own reveal gate. No later-act ids are referenced.

Consistency: zone ids shared across all three files; item ids ⊆ `data/items` (41);
referenced prop scenes and every referenced audio file exist on disk; the three new prop
surfaces are shipped in this PR.

## For CODE agent (wiring checklist)

1. `scenes/districts/hospital.tscn` — 10 zones per `prop_manifest.md`;
   `props/examine.tscn` ×8 (one per note); `props/puzzle_3d.tscn` on the diesel-plant pad
   wired to `PowerSwitch` (`generator_hospital`); `props/streetlight_3d.tscn` ×6 usable +
   bay flicker.
2. Loot rolls keyed by `DistrictData.Stage`; enforce R1 (chain solvable in DARK, no
   lockpick), R2 (serum ramp starts here), R4 (no firearms), R6 (pharmacy/morgue non-RNG),
   R7 (**notes 06/07/08 gated to STREETS** — the spawner must honour `min_stage` on notes,
   not only on items), R8 (no blueprint).
3. Lock `z_pharmacy` with `hospital_fix_key_01` (reception night drawer, unlocked).
4. Lore notes → existing pickup flow; add the `hospital` id list to `DistrictLoot.LORE_DOCS`:
   `hospital_note_01` … `hospital_note_08`.
5. `z_morgue` stays unlit at every stage; `z_records` drops detail beds to −12 dB so the
   reveal documents land in silence.
6. New prop surfaces available: `surfaces/hospital_curtain_512.png`,
   `surfaces/xray_lightbox_512.png`, `surfaces/morgue_drawers_512.png`.
7. Journal/RADIO unlocks: reading note 06 or 07 is the natural trigger for the Architect
   world-bible entries (they share the same reveal gate).

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE agent runs them. This pass validated statically:
JSON parse, id cross-refs, path existence, OGG header parse.)

## For LOCALE agent — add to all 13 locales

`LORE_HOSPITAL_<NN>_TITLE` / `LORE_HOSPITAL_<NN>_TEXT`, NN ∈ 01–08 → **16 keys**; en source
= the `en` fields in `content/districts/hospital/lore_notes.json`.

```
LORE_HOSPITAL_01_TITLE  LORE_HOSPITAL_01_TEXT
LORE_HOSPITAL_02_TITLE  LORE_HOSPITAL_02_TEXT
LORE_HOSPITAL_03_TITLE  LORE_HOSPITAL_03_TEXT
LORE_HOSPITAL_04_TITLE  LORE_HOSPITAL_04_TEXT
LORE_HOSPITAL_05_TITLE  LORE_HOSPITAL_05_TEXT
LORE_HOSPITAL_06_TITLE  LORE_HOSPITAL_06_TEXT
LORE_HOSPITAL_07_TITLE  LORE_HOSPITAL_07_TEXT
LORE_HOSPITAL_08_TITLE  LORE_HOSPITAL_08_TEXT
```

## Remaining districts

`gas_station → police → warehouses → industrial → substation → power_station`.
