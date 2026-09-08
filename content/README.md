# content/ — Authored Game Content (data, not code)

Owner: CONTENT agent. Wiring (scenes/.tscn, resources/.tres, loaders) is done by the CODE agent.
This directory is the **source of truth for authored content**; `scenes/` and `data/` are wired from it.

## Canon
- Single source of truth: `docs/GDD.md` (frozen). District chain (GDD §4):
  `suburbs → residential → park → school → hospital → gas_station → police → warehouses → industrial → substation → power_station` (11 districts).
- District stages (GDD §4.2): `DARK = 0, PARTIAL = 1, STREETS = 2, FULL = 3`.
- Item IDs must exist in `data/items/*.tres` (canonical list in GDD §17). Never invent IDs here.

## Layout
```
content/
  README.md                     <- this file
  districts/<district_id>/
    lore_notes.json             <- readable world notes (document / photo / audio_log)
    item_spawns.json            <- loot tables per stage + fixed puzzle-critical spawns
    prop_manifest.md            <- prop / examine-spot / ambience placement plan
  world/                        <- world bible (see docs/CONTENT_WORLD_BIBLE.md)
    characters.json  factions.json  history.json  radio_transcripts.json
  lore/                         <- world bible, found-text layer
    diary_entries.json  news_clippings.json
```
District packs reference `world/` and `lore/` **by id only** via `world_refs` arrays
(no copied prose); contract and i18n inventory live in `docs/CONTENT_WORLD_BIBLE.md`.

## lore_notes.json schema
```jsonc
{
  "district": "suburbs",          // district id, matches DISTRICT_NAME_<ID> i18n keys
  "version": 1,
  "notes": [{
    "id": "suburbs_note_01",      // stable, unique, snake_case
    "item_type": "document",      // document | photo | audio_log (all exist in data/items/)
    "i18n_keys": {
      "title": "LORE_SUBURBS_01_TITLE",
      "text":  "LORE_SUBURBS_01_TEXT"
    },
    "en": { "title": "...", "text": "..." },   // English source text (for translators)
    "location_hint": "where in the district it sits",
    "min_stage": 0,               // earliest Stage it can appear (0 = DARK)
    "weight": 100                 // spawn priority vs other notes in the same district
  }]
}
```

### i18n contract (handoff to the locale agent)
- Key convention: `LORE_<DISTRICT_UPPER>_<NN>_TITLE` / `_TEXT`.
- `en` values here are the **source strings**. The locale agent adds the keys to all 13 locales;
  this repo rule (no hardcoded UI strings) means notes are displayed via `tr(key)`.
- CONTENT never edits `data/i18n/` or `locales/`.

## item_spawns.json schema
```jsonc
{
  "district": "suburbs",
  "version": 1,
  "tables": {
    "DARK":    [{ "item": "battery", "weight": 18, "min": 1, "max": 1 }],
    "PARTIAL": [], "STREETS": [], "FULL": []     // stage keys match DistrictData.Stage
  },
  "container_modifiers": { "car_trunk": 1.0 },   // multiplier on rolled qty, container types are
                                                  // advisory until the code agent fixes a list
  "fixed_spawns": [{ "item": "fuse", "zone": "z_garage_row", "qty": 2,
                     "reason": "guarantee first transformer puzzle is solvable in DARK" }],
  "rules": ["prose guarantees the code agent must enforce"]
}
```

## prop_manifest.md
Human-readable placement plan per zone. Prop references point to existing scenes
(`scenes/props/*.tscn`, `scenes/pickups/*.tscn`) and ambience to existing files under
`assets/audio/ambience/`. Gaps are listed explicitly at the bottom (art/audio prompts).

## Id scoping contract (added by the 2026-09-08 pipeline audit)

- **Note ids are globally unique**: `<district>_note_NN`. Verified across all packs — no
  collisions (`docs/CONTENT_PIPELINE_AUDIT.md`).
- **Zone ids are district-scoped**, not global. `z_exit_east`, `z_exit_north` and
  `z_boiler_room` legitimately appear in more than one district; they are only ever
  meaningful as the pair `(district_id, zone_id)`. Code must key zone lookups by both —
  never build a flat global zone table. Within one district, zone ids must be unique and
  must appear identically in all three pack files.
- **Fixed-spawn ids are globally unique**: `<district>_fix_<purpose>_NN`.
- **world_refs reachability rule**: a district may only reference world-bible ids whose
  `reveal.district` is that district itself (with `min_stage` respected) or a district on
  its *guaranteed* prerequisite closure (`powered_by` transitively, all at FULL per GDD
  §4.3). Example: `park` guarantees only `suburbs`; `gas_station` guarantees `park` +
  `suburbs`; `school`/`hospital` guarantee `residential` + `suburbs`.

## Rules for content authors
1. One district = deep pass first (template), then replicate.
2. Every item id, prop scene, audio file referenced must already exist — content never blocks on art (YAGNI).
3. Lore must fit the GDD arc: blackout catastrophe, restoring the grid district by district,
   the truth about the disaster, the Keeper in the center (GDD §12.3–12.4).
4. Status/quests/enemies are CODE territory — reference them, never define new systems here.
