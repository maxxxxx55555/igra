# Content Handoff — District `power_station` (district 11, CHAIN TERMINAL / FINALE)

Task: district-level content per GDD §4.1 canon order (… → substation → **power_station**).
Name verified directly against `docs/GDD.md` §4.1 and `data/districts/district_power_station.tres`.
Scope respected: only `content/**`, `assets/textures/**`, `assets/audio/**` (header
verify only — no gaps) and `docs/**`. No `*.gd`, `*.tscn`, `*.tres`, `tools/`, `locales/`,
`data/`, root `*.md`. Frozen docs untouched. **Lore only:** this pack resolves people and
paper and never references GDD §12.4 content or code mechanics (CODE's zone).

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/power_station/lore_notes.json` | 8 notes (3 documents, 3 photos, 2 audio logs), stage-gated 0–3, `world_refs` ids |
| `content/districts/power_station/item_spawns.json` | 4 stage tables + 10 fixed spawns + 10 container modifiers + rules R1–R8 |
| `content/districts/power_station/prop_manifest.md` | 10-zone placement plan, stage-state table, art/audio gaps (none — both ship) |
| `docs/CONTENT_DISTRICT_POWER_STATION.md` | this handoff |

Also in this PR: the power_station asset pass (no new binaries needed — both lit twins
ship; re-measured for the record and ledgered in `docs/ASSET_LICENSES.md`), the
power_station audio header-verification (both beds + 4 one-shots; numbers recorded in
`docs/AUDIO_COVERAGE.md`, no spec appended), and the district-11 row + full re-run in
`docs/CONTENT_PIPELINE_AUDIT.md` (the CONTENT RELEASE CERTIFICATE).

## The terminal closure (computed, double-check this first)

`power_station.powered_by = [&"substation"]` — GDD §4.3 requires the prerequisite at FULL.
The guaranteed history at arrival is substation's seven-district closure **plus
substation itself**:

- **Union (guaranteed at arrival): `suburbs`, `residential`, `park`, `hospital`,
  `warehouses`, `police`, `industrial`, `substation` — eight districts, all stages**
  (every packed district except the two leaves).

Every world id gated on any of those eight is safe here regardless of its own `min_stage`.
**NOT guaranteed: `school`, `gas_station`** (leaves of the `powered_by` graph — no id is
gated on them, and the pack never leans on their content). `radio_03_keeper_reversal` is
gated on **power_station itself** at min_stage 1 (`content/world/radio_transcripts.json`) —
this is the first and only district where it is legal, and `power_station_note_03`
(min_stage 1) meets the gate exactly. Council decision (skill `council`, logged):
finale-convergence — the terminal district legally closes every open thread (Architect
memorandum, Keeper's answer, crew's last camp, Manya's names, the trees, the watch, the
bench proof at the center), consuming the last six never-referenced world ids; after this
pack, all 37 world-bible ids have been referenced at least once across the chain.

### world_refs reachability (computed `powered_by` closure + self gate)

20 `world_refs` (20 distinct), all inside the eight-district closure or the self gate:

- suburbs-gated: `char_marat`, `char_grid_crew_recorder`, `faction_grid_crew` (note 01),
  `faction_city_power`, `hist_blackout_night` (04), `char_old_anya`, `hist_bench_proof` (08)
- park-gated: `char_keeper`, `hist_radio_call` (03), `char_petrov` (07, `min_stage 2`
  matching his own gate), `news_trees_listen` (08)
- residential-gated: `char_babka_manya`, `diary_manya_01` (07, `min_stage 2` matching the
  diary's own gate)
- hospital-gated (Act II Architect set, paced `min_stage >= 2` matching their own STREETS
  gate and the warehouses/industrial/substation precedent): `char_architect`,
  `faction_project_architect`, `hist_project_architect` (05)
- park-gated diary pair: `diary_keeper_01`, `diary_keeper_03` (06)
- power_station-gated (self, min_stage 1, carried at the gate exactly): 
  `radio_03_keeper_reversal` (03)

**First uses in the chain:** `radio_03_keeper_reversal`, `diary_keeper_01`,
`diary_keeper_03`, `diary_manya_01`, `news_trees_listen`, `char_old_anya` — the last six
never-referenced ids. Together with the substation pack's four first uses
(`radio_02_grid_crew_relay`, `hist_crew_walk_suburbs`, `hist_bench_proof`,
`diary_keeper_02`), **all 37 world-bible ids are now referenced at least once.**
**Thread closures:** Architect thread resolves in person (05 — the memorandum, lore only,
no mechanics); Keeper/radio thread resolves on the air (03 — the answer) and in the
bunker (06 — the racks); crew thread resolves at the gate and the camp (01, 07, 08);
Manya's names rule resolves at the center (07); the trees, the watch and the bench proof
converge in the last word (08).

## Canon anchors used (verified in-repo, 2026-09-09)

- Prereq: `powered_by = [&"substation"]` (`data/districts/district_power_station.tres`);
  `map_position = (300, 300)`. Powers nothing — the terminal.
- GDD §12.3: **Act III = D9–11** — power_station is D11, the finale; there is no road
  past it (the towers / note_08 mark the terminus in prose only, never in UI).
- Enemies: `destroyer`, `destroyer`, `watcher` (`enemy_pool.gd`) — **double destroyer,
  the heaviest lead in the chain**: no light reaction at all and both break nearby
  streetlights while patrolling (`destroyer_3d.gd`). R5 sets the finale tier: light is
  bait, not even a consumable; twin hums (12 m) are the cues; the watcher holds the
  corridor (2 s stun then rage ×1.25 / 5 s, 15 m scream pulls BOTH destroyers at once).
- Themed loot: `district_loot.gd` BY_DISTRICT `power_station = fuse, transistor, medkit`
  → chain parts plus mercy (medicine), mirrored in the tables and
  `power_station_fix_med_01`/`_med_02`.
- **No blueprint:** `BLUEPRINTS` canon is exactly four districts (residential, park, police,
  warehouses) — power_station is not one of them, and GDD §9 lists no D11 craft (R7).
- Story doc: `doc_core_station` (800 MW passport, DO NOT START AFTER 23:00, the pencil
  line "generators no longer produce current — they produce voices") → extended, never
  copied, by `power_station_note_04` (the pencil line's author).
- Puzzle: `puzzle_system.gd` `reactor_power_station` → the pad in `z_reactor_room`
  (GG cell). **Cited by id and zone only** — the reward and mechanics are CODE's zone
  and are never stated in this pack (R4).
- Ambience details exist, header-verified by this PR: `power_station_generator_thrum`
  (0.0), `power_station_hv_whine` (0.0), `power_station_cooling_fan` (0.0),
  `power_station_breaker_clunk` (3.0); dark bed exists; **lit bed ships too** (both
  header-verified — see AUDIO_COVERAGE for numbers). **No audio gap.**
- Music: `music_manager.gd` maps power_station → `music_ambient_dark.wav` (exists).
  `district_themes.gd` power_station row is colour-only (no `"music"` key — same class as
  substation/industrial; no mismatch to flag). Theme accent `#f4f45d` is hotter than the
  ember token (STYLE_GUIDE §2); manifest keeps it off surfaces (small emissives only).
- Weather is **fog**; the hall reads through fog at every stage.

Consistency: zone ids shared across all three files; item ids ⊆ `data/items` (41); note ids
and fixed-spawn ids globally unique; referenced prop scenes and audio files exist (no
exemptions needed); no new textures (both lit twins ship).

## For CODE agent (wiring checklist)

1. `scenes/districts/power_station.tscn` already exists with the sibling node contract —
   populate 10 zones per `prop_manifest.md`; `props/examine.tscn` ×8;
   `props/puzzle_3d.tscn` on the reactor pad wired to `PowerSwitch`
   (`reactor_power_station` — id and zone only, see R4); usable
   `props/streetlight_3d.tscn` ×11 across gate/hall×2/reactor/operations/yard/camp/loft/
   gate pier/towers/yard north. **Never** place a lamp in `z_archive` or `z_bunker`
   (stay unlit at every stage — R8).
2. Loot rolls keyed by `DistrictData.Stage`; enforce R1 (chain solvable in DARK: 2 cable /
   2 fuse / 2 transistor + archive key, no lockpick), R2 (fuse/transistor never in DARK rolls;
   molotov from PARTIAL, noise_bomb from STREETS), R6 (scripted caches never empty),
   R7 (**no blueprint id may spawn here — power_station has no BLUEPRINTS row**).
3. Lock `z_archive` with `power_station_fix_key_01` (operations desk drawer, unlocked).
   `z_bunker` is unlocked but unwired (no lamp, no lock — read by hand-lamp spill).
4. Lore notes → existing pickup flow; add the `power_station` id list to
   `DistrictLoot.LORE_DOCS`: `power_station_note_01` … `power_station_note_08`.
5. Double-destroyer patrol: destroyer A on the turbine hall, destroyer B on the cooling
   yard + towers edge (both WILL break relit lamps — intended, do not guard against it);
   watcher on the ops/archive corridor (its scream pulls both destroyers — R5). The DARK
   chain must never require light, combat or a chase (R1).
6. Textures: both `_lit` twins ship pre-existing (`tiles/power_station_floor_lit.png` /
   `power_station_wall_lit.png`, re-measured for the record by this PR) — follow the
   shipped `_lit` convention for `district_grading.gd::_apply_ground`.
7. Map wiring note: power_station is the map's row-2 terminus — the substation east-gate
   road enters at `D`; there is no exit past the towers (fence + fog).

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE runs them. This pass validated statically: JSON
parse, id cross-refs, path existence, Ogg header parse, image metrics.)

## For LOCALE agent — add to all 13 locales

`LORE_POWER_STATION_<NN>_TITLE` / `LORE_POWER_STATION_<NN>_TEXT`, NN ∈ 01–08 → **16 keys**;
en source = the `en` fields in `content/districts/power_station/lore_notes.json`.

```
LORE_POWER_STATION_01_TITLE  LORE_POWER_STATION_01_TEXT
LORE_POWER_STATION_02_TITLE  LORE_POWER_STATION_02_TEXT
LORE_POWER_STATION_03_TITLE  LORE_POWER_STATION_03_TEXT
LORE_POWER_STATION_04_TITLE  LORE_POWER_STATION_04_TEXT
LORE_POWER_STATION_05_TITLE  LORE_POWER_STATION_05_TEXT
LORE_POWER_STATION_06_TITLE  LORE_POWER_STATION_06_TEXT
LORE_POWER_STATION_07_TITLE  LORE_POWER_STATION_07_TEXT
LORE_POWER_STATION_08_TITLE  LORE_POWER_STATION_08_TEXT
```

## Remaining districts

None — the chain is complete (11/11). See `docs/CONTENT_PIPELINE_AUDIT.md` (CONTENT
RELEASE CERTIFICATE) for the full standing audit.
