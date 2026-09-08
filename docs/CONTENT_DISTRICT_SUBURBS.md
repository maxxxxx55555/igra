# Content Handoff — District `suburbs` (deep template pass)

Task: expand district level content per GDD — lore notes, item spawns, prop placement.
Scope respected: this task touched **only `content/**` and `docs/**`**. No `*.gd`, `tools/`,
`locales/`, `PLAN.md`, `data/`, `scenes/` were modified. GDD/PRODUCTION_BIBLE untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/README.md` | Format contract for `content/districts/<id>/` (all 11 districts later) |
| `content/districts/suburbs/lore_notes.json` | 8 authored notes (3 documents, 2 photos, 2 audio logs + roster), stage-gated |
| `content/districts/suburbs/item_spawns.json` | 4 stage loot tables + 8 fixed spawns + container modifiers + rules R1–R5 |
| `content/districts/suburbs/prop_manifest.md` | 8-zone placement plan, stage-state table, art/audio gaps |

Consistency: zone ids (`z_*`), note ids (`suburbs_note_*`), fixed-spawn ids and item ids are
cross-checked — every item id exists in `data/items/*.tres`, every referenced scene/audio exists.

## For CODE agent (wiring checklist)

1. `scenes/districts/suburbs.tscn` — feed `StreetBuilder`/`Props` from `prop_manifest.md` zone plan;
   place `props/streetlight_3d.tscn` ×5 usable + exit beacon; `props/examine.tscn` ×8 at noted anchors.
2. Spawn rolls: read `item_spawns.json` tables keyed by `DistrictData.Stage` (DARK/PARTIAL/STREETS/FULL);
   enforce rules R1 (puzzle solvability guarantee) and R4 (no firearms in suburbs).
3. Lock the corner-shop back room with `suburbs_fix_key_01` key.
4. Lore notes → the existing document/audio_log pickup flow (loader of `data/lore/lore.json`); note the
   legacy `lore.json` uses old 5-district ids — migration/mapping is CODE's call, content ids here are new.
5. Stage ambience per manifest table (suburbs detail loops already exist in
   `assets/audio/ambience/district_details/`).

Gates to run after wiring (headless, exit 0): compile, signal arity, i18n, asset check.

## For LOCALE agent (QWEN) — add these keys to all 13 locales

Key pattern: `LORE_SUBURBS_<NN>_TITLE` / `LORE_SUBURBS_<NN>_TEXT`. English source strings are the
`en` fields in `content/districts/suburbs/lore_notes.json` (single source; do not duplicate edits).
16 keys total: NN ∈ 01–08.

## Remaining districts (follow-ups, same template)

`residential → park → school → hospital → gas_station → police → warehouses → industrial →
substation → power_station`. GDD-canon flavor per district is already in the chain order and
legacy `story` lines; each pass = same 3-file set + handoff addendum.
