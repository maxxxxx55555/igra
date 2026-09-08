# Content Handoff — District `park` (district 3)

Task: district-level content per GDD canon order (residential → park).
Scope respected: only `content/**` and `docs/**` touched. No `*.gd`, `tools/`, `locales/`,
`PLAN.md`, `data/`, `scenes/`. GDD/PRODUCTION_BIBLE/HANDOFF untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/park/lore_notes.json` | 8 notes (3 documents, 2 photos, 2 audio logs + radio capture), stage-gated, world_refs ids |
| `content/districts/park/item_spawns.json` | 4 stage tables + 8 fixed spawns + 6 container modifiers + rules R1–R6 |
| `content/districts/park/prop_manifest.md` | 9-zone placement plan, stage-state table, gaps |
| `docs/CONTENT_DISTRICT_PARK.md` | this handoff |

Also in this PR: park asset pass (lit tiles + pond ice, `docs/ASSET_LICENSES.md`),
park lit-bed spec appended to `docs/AUDIO_COVERAGE.md`, and the world bible
(`content/world/`, `content/lore/`, `docs/CONTENT_WORLD_BIBLE.md`) that the
`world_refs` ids in this pack resolve against.

## Canon anchors used (verified in-repo)

- Prereq: `powered_by = [&"suburbs"]` (`data/districts/district_park.tres`); park powers
  `gas_station` and `police`. **Correction:** `docs/CONTENT_DISTRICT_RESIDENTIAL.md`
  previously said residential powers park — false per the tres; patched that line (residential
  powers `school` + `hospital`).
- Enemies: `crawler`, `hunter`, `shadow` (`enemy_pool.gd`) — hunter = noise-discipline lesson.
- Blueprint: `blueprint_flashlight_battery` (`district_loot.gd` BLUEPRINTS).
- Story doc: `doc_streetlight_manifesto` = the Keeper («сорок лет… теперь чиню наоборот») →
  `park_note_01`/`park_note_06` and world-bible `char_keeper`.
- Act I radio voice «идите на электростанцию» (GDD §12.3) → `park_note_07` +
  `content/world/radio_transcripts.json::radio_01_power_station`.
- Ambience details exist and are consumed (`district_atmosphere.gd`):
  `park_bare_trees_wind`, `park_branch_snap`, `park_leaves_skitter`, `park_distant_city_hum`.

Consistency: zone ids shared across the three files; item ids ⊆ `data/items` (41);
referenced scenes/audio exist; `world_refs` ids resolve against `content/world/*.json`
(verified in the world-bible step of this PR).

## For CODE agent (wiring checklist)

1. `scenes/districts/park.tscn` — manifest zone plan; `props/streetlight_3d.tscn` ×5 usable +
   gate flicker; `props/examine.tscn` ×8; `props/puzzle_3d.tscn` at the keeper's-shed pad
   wired to `PowerSwitch`; pond plane with `surfaces/pond_ice_512.png`.
2. Rolls keyed by `DistrictData.Stage`; enforce R1 (repair chain) and R4 (no firearms).
3. Lock the shed with `park_fix_key_01`; shed caches non-RNG (R6).
4. Lore notes → existing pickup flow; add `park` id list to `DistrictLoot.LORE_DOCS`.
5. Noise teaching: branch-snap surface on alley litter; hunter aggro on running noise there.

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE agent runs them.)

## For LOCALE agent — add to all 13 locales

`LORE_PARK_<NN>_TITLE` / `LORE_PARK_<NN>_TEXT`, NN ∈ 01–08; en source = the `en` fields in
`content/districts/park/lore_notes.json`. 16 keys.

## Remaining districts

`school → hospital → gas_station → police → warehouses → industrial → substation →
power_station`.
