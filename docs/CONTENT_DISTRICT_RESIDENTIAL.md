# Content Handoff — District `residential` (district 2)

Task: expand district-level content per GDD canon order (suburbs → residential).
Scope respected: this pass touched **only `content/**` and `docs/**`**. No `*.gd`, `tools/`,
`locales/`, `PLAN.md`, `data/`, `scenes/` were modified. GDD/PRODUCTION_BIBLE untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/residential/lore_notes.json` | 8 authored notes (4 documents, 2 photos, 2 audio logs), stage-gated, canon-linked |
| `content/districts/residential/item_spawns.json` | 4 stage loot tables + 8 fixed spawns + 7 container modifiers + rules R1–R6 |
| `content/districts/residential/prop_manifest.md` | 8-zone placement plan, stage-state table, art/audio gaps |
| `docs/STYLE_GUIDE.md`, `docs/ASSET_LICENSES.md` | authored in the asset pass (same PR) |
| `docs/AUDIO_COVERAGE.md` | audio gap audit (same PR) |

## Canon anchors used (verified in-repo)

- Chain: `suburbs → residential`, `powered_by = [&"suburbs"]` (`data/districts/district_residential.tres`);
  residential powers `park` and `school`.
- Enemies: `shadow`, `crawler` ×2 (`scripts/enemies/enemy_pool.gd`).
- Blueprint: `blueprint_flashlight_brightness` (`scripts/world/district_loot.gd` BLUEPRINTS).
- Story doc: `doc_old_woman` = house 24 / Babka Manya, «свет — не электричество»
  (`data/documents/documents_catalog.json`) → `residential_note_01` answers it.
- Grid-crew arc: suburbs_note_04/07 → `residential_note_07` (log 3, boiler-room cache).
- Ambience details already exist and are consumed by `scripts/world/district_atmosphere.gd`:
  `residential_pipe_creak`, `residential_tv_murmur`, `residential_window_rattle`.

Consistency: zone ids (`z_*`), note ids (`residential_note_*`), fixed-spawn ids and item ids
are cross-checked — every item id exists in `data/items/*.tres` (41 ids), every referenced
scene exists in `scenes/props|pickups/`, every referenced audio file exists under
`assets/audio/ambience/`.

## For CODE agent (wiring checklist)

1. `scenes/districts/residential.tscn` — feed `StreetBuilder`/`Props` from the manifest zone
   plan; place `props/streetlight_3d.tscn` ×6 usable + gate flicker; `props/examine.tscn` ×8
   at noted anchors; `props/puzzle_3d.tscn` on the boiler-room pad wired to the existing
   `PowerSwitch` at (8,0,8).
2. Spawn rolls: read `item_spawns.json` tables keyed by `DistrictData.Stage`; enforce R1
   (repair chain guarantee: 2× cable/fuse/transistor) and R4 (no firearms).
3. Lock the boiler room with `residential_fix_key_01`; keep house-24 caches non-RNG (R6).
4. Lore notes → existing document/audio_log pickup flow (same loader contract as suburbs
   LORE_DOCS; add the `residential` id list next to `suburbs` in `DistrictLoot.LORE_DOCS`).
5. Safe pocket: no enemy pathing within ~6 m of the z_house24 door.
6. `EmissiveWindows`: map the 7th-floor "watching window" (z_block_east) to PARTIAL-on.

Gates to run after wiring (headless, exit 0): compile, signal arity, i18n, asset check.

## For LOCALE agent — add these keys to all 13 locales

Key pattern: `LORE_RESIDENTIAL_<NN>_TITLE` / `LORE_RESIDENTIAL_<NN>_TEXT`. English source
strings are the `en` fields in `content/districts/residential/lore_notes.json` (single
source; do not duplicate edits). 16 keys total: NN ∈ 01–08.

## Remaining districts (follow-ups, same template)

`park → school → hospital → gas_station → police → warehouses → industrial → substation →
power_station`.
