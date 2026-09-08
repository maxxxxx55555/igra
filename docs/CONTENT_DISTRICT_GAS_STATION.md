# Content Handoff — District `gas_station` (district 6)

Task: district-level content per GDD §4.1 canon order (… → school → hospital →
**gas_station**). Name verified directly against `docs/GDD.md` §4.1 (the root
`ARENA_NEXT_PROMPT.md` is stale until CODE refreshes it post-merge and was **not** used).
Scope respected: only `content/**`, `assets/textures/**` and `docs/**`. No `*.gd`, `*.tscn`,
`*.tres`, `tools/`, `locales/`, `data/`, root `*.md`. Frozen docs untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/gas_station/lore_notes.json` | 8 notes (4 documents, 2 photos, 2 audio logs), stage-gated 0–3, `world_refs` ids |
| `content/districts/gas_station/item_spawns.json` | 4 stage tables + 9 fixed spawns + 8 container modifiers + rules R1–R8 |
| `content/districts/gas_station/prop_manifest.md` | 9-zone placement plan, stage-state table, art/audio gaps |
| `docs/CONTENT_DISTRICT_GAS_STATION.md` | this handoff |

Also in this PR: gas_station asset pass (2 lit tile twins + fuel-pump surface, ledgered in
`docs/ASSET_LICENSES.md`), the `gas_station_lit.ogg` spec appended to
`docs/AUDIO_COVERAGE.md`, and the pipeline-wide audit `docs/CONTENT_PIPELINE_AUDIT.md`.

## Canon anchors used (verified in-repo, 2026-09-08)

- Prereq: `powered_by = [&"park"]` (`data/districts/district_gas_station.tres`) — **not**
  hospital, despite the chain order in GDD §4.1 reading `hospital → gas_station`.
  `map_position = (180, 180)`.
- **Flag for CODE (data, not mine to fix):** `gas_station` is a **leaf** of the power graph
  — no district's `.tres` lists it in `powered_by` (`industrial` takes `warehouses` +
  `police`). Same class of finding as `school` in this PR. Content is written leaf-safe.
- Enemies: `hunter`, `shadow`, `crawler` (`enemy_pool.gd`) — hunter leads, so the noise
  lesson park introduced becomes this district's economy (R5, and `gas_station_note_03`
  states it in-world: "an engine and a man running sound the same").
- Themed loot: `district_loot.gd` BY_DISTRICT `gas_station = gas_canister, battery, scrap,
  bottle` → mirrored in the tables and in `gas_station_fix_fuel_01` / `_craft_01`.
- **No blueprint** in gas_station (BLUEPRINTS = residential/park/police/warehouses) → R8.
- Story doc: `doc_scavenger` (the list: mirrors, toys, switches) → extended, never copied,
  by `gas_station_note_01` (the *second* page) and echoed by the camp rules in note 08.
- Puzzle: `puzzle_system.gd` `fuse_gas_station` (reward 125 coins, `power_stage` 2) → the
  genset pad in `z_generator_yard`. The district's own puzzle is a **fuse** puzzle, so the
  fuse fixed spawn sits in the kiosk drawer on the pump island by design.
- Ambience details exist, header-verified this pass (all 1 ch / 44.1 kHz / 30.000 s):
  `gas_station_sign_buzz` (0.0), `gas_station_pump_hum` (0.0), `gas_station_gravel_crunch`
  (0.0), `gas_station_car_pass` (2.2); bed `gas_station_dark.ogg` (36.000 s). Lit bed is a
  **real gap** — spec only, see AUDIO_COVERAGE G2e.
- Music: `music_manager.gd` maps gas_station → `downtown.wav`; `district_themes.gd` says
  `industrial.wav`. Same class of mismatch as school/hospital — flagged, not touched.

### world_refs reachability (why this pack can use the Keeper)

`gas_station` needs park FULL, and park needs suburbs FULL (GDD §4.3: every prereq at FULL).
So at arrival the player has completed **suburbs and park at every stage** — every
suburbs- and park-gated world id is safe here regardless of its own `min_stage`. This pack
therefore finally pays off the Keeper material (`char_keeper`, `faction_keepers`,
`hist_keeper_reversal`) and the Act I radio call (`char_radio_voice`,
`radio_01_power_station`, `hist_radio_call`).
**Not** referenced: residential- and hospital-gated ids (that branch may be untouched) —
which also keeps the Act II Architect reveal at its hospital-STREETS gate
(CONTENT_WORLD_BIBLE rule 3).

Consistency: zone ids shared across all three files; item ids ⊆ `data/items` (41);
referenced prop scenes and audio files exist; the new textures ship in this PR.

## For CODE agent (wiring checklist)

1. `scenes/districts/gas_station.tscn` — 9 zones per `prop_manifest.md`;
   `props/examine.tscn` ×8; `props/puzzle_3d.tscn` on the genset pad wired to `PowerSwitch`
   (`fuse_gas_station`); `props/streetlight_3d.tscn` ×5 usable + canopy flicker.
2. Loot rolls keyed by `DistrictData.Stage`; enforce R1 (chain solvable in DARK, no
   lockpick), R2 (molotovs only from PARTIAL), R4 (no firearms), R6 (camp/tanker non-RNG),
   R7 (**no open-flame item may spawn on the pump island, tanker apron or tank hatches**),
   R8 (no blueprint).
3. Lock `z_service_bay` with `gas_station_fix_key_01` (till drawer, unlocked).
4. Lore notes → existing pickup flow; add the `gas_station` id list to
   `DistrictLoot.LORE_DOCS`: `gas_station_note_01` … `gas_station_note_08`.
5. Noise teaching: gravel surface on the forecourt/apron tied to
   `gas_station_gravel_crunch.ogg`; hunter aggro on running noise there (mirrors the park
   alley wiring note).
6. New texture available: `surfaces/fuel_pump_512.png`; lit tiles
   `tiles/gas_station_floor_lit.png` / `_wall_lit.png` follow the shipped `_lit` convention
   for `district_grading.gd::_apply_ground`.

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE runs them. This pass validated statically: JSON parse,
id cross-refs, path existence, Ogg header parse, image metrics.)

## For LOCALE agent — add to all 13 locales

`LORE_GAS_STATION_<NN>_TITLE` / `LORE_GAS_STATION_<NN>_TEXT`, NN ∈ 01–08 → **16 keys**;
en source = the `en` fields in `content/districts/gas_station/lore_notes.json`.

```
LORE_GAS_STATION_01_TITLE  LORE_GAS_STATION_01_TEXT
LORE_GAS_STATION_02_TITLE  LORE_GAS_STATION_02_TEXT
LORE_GAS_STATION_03_TITLE  LORE_GAS_STATION_03_TEXT
LORE_GAS_STATION_04_TITLE  LORE_GAS_STATION_04_TEXT
LORE_GAS_STATION_05_TITLE  LORE_GAS_STATION_05_TEXT
LORE_GAS_STATION_06_TITLE  LORE_GAS_STATION_06_TEXT
LORE_GAS_STATION_07_TITLE  LORE_GAS_STATION_07_TEXT
LORE_GAS_STATION_08_TITLE  LORE_GAS_STATION_08_TEXT
```

## Remaining districts

`police → warehouses → industrial → substation → power_station`.
