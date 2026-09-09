# Content Handoff — District `substation` (district 10)

Task: district-level content per GDD §4.1 canon order (… → industrial → **substation**).
Name verified directly against `docs/GDD.md` §4.1 and `data/districts/district_substation.tres`.
Scope respected: only `content/**`, `assets/textures/**`, `assets/audio/**` (header
verify + spec only) and `docs/**`. No `*.gd`, `*.tscn`, `*.tres`, `tools/`, `locales/`,
`data/`, root `*.md`. Frozen docs untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/substation/lore_notes.json` | 8 notes (3 documents, 3 photos, 2 audio logs), stage-gated 0–3, `world_refs` ids |
| `content/districts/substation/item_spawns.json` | 4 stage tables + 10 fixed spawns + 10 container modifiers + rules R1–R8 |
| `content/districts/substation/prop_manifest.md` | 10-zone placement plan, stage-state table, art/audio gaps |
| `docs/CONTENT_DISTRICT_SUBSTATION.md` | this handoff |

Also in this PR: the substation asset pass (2 lit tile twins, §4.1-verified, ledgered in
`docs/ASSET_LICENSES.md` — the shipped dark twins are seam-probed first per the warehouses
precedent), the `substation_lit.ogg` full spec promoted from the G3 one-liner in
`docs/AUDIO_COVERAGE.md`, and the district-10 row + full re-run in
`docs/CONTENT_PIPELINE_AUDIT.md`.

## The single-parent closure (computed, double-check this first)

`substation.powered_by = [&"industrial"]` — GDD §4.3 requires the prerequisite at FULL.
Industrial is itself the first two-parent convergence, so the guaranteed history at
arrival is industrial's six-district union **plus industrial itself**:

- **industrial branch:** industrial → {warehouses → hospital → residential → suburbs} ∪
  {police → park → suburbs}
- **Union (guaranteed at arrival): `suburbs`, `residential`, `park`, `hospital`,
  `warehouses`, `police`, `industrial` — seven districts, all stages.**

Every world id gated on any of those seven is safe here regardless of its own `min_stage`.
**NOT guaranteed: `school`, `gas_station`** (leaves of the `powered_by` graph — neither is
an ancestor of industrial), **and `power_station`** (a descendant, not an ancestor —
substation feeds *it*). So `radio_03_keeper_reversal` (power_station-gated) must never
spawn here. `radio_02_grid_crew_relay` is gated on **substation itself** at min_stage 1
(`content/world/radio_transcripts.json`) — this is the first district where it is legal,
and `substation_note_07` (min_stage 2) respects substation's own stage progression, not
just "district reached". Council decision (skill `council`, logged): crew-destination —
the crew walked two districts to reach this fence (log 21), so the pack resolves their
walk (arrival, the tap found, the tape, the tracks east) while the Architect's *person*
stays withheld for the finale; only the tap mechanism (faction + history + denial) ships
here, paced at STREETS per the warehouses/industrial precedent.

### world_refs reachability (computed `powered_by` closure + self gate)

20 `world_refs` (18 distinct), all inside the seven-district closure or the self gate:

- suburbs-gated: `hist_blackout_night`, `faction_city_power` (note 01),
  `char_marat`, `char_grid_crew_recorder`, `faction_grid_crew`, `hist_crew_walk_suburbs`
  (notes 03/08), `news_rolling_outages` (04), `hist_bench_proof` (07)
- residential-gated: none this pack (the residential set rests; `diary_manya_01` is
  reserved for the finale)
- park-gated: `diary_keeper_02` (04), `char_keeper`, `faction_keepers`,
  `hist_keeper_reversal` (06), `char_radio_voice`, `radio_01_power_station` (08)
- hospital-gated (Act II Architect set, paced `min_stage >= 2` matching their own STREETS
  gate and the warehouses/industrial precedent): `hist_project_architect`,
  `faction_project_architect`, `news_architect_denied` (05)
- substation-gated (self, min_stage 1, carried at min_stage 2 for district rhythm):
  `radio_02_grid_crew_relay` (07)

**First uses in the chain:** `radio_02_grid_crew_relay`, `hist_crew_walk_suburbs`,
`hist_bench_proof`, `diary_keeper_02` (all four never referenced by districts 1–9).
**Not referenced:** school/gas_station branch content, `char_architect` (withheld for the
finale — the person, not the program, is the D11 reveal), all power_station-gated ids
(`radio_03_keeper_reversal`), `diary_keeper_01`, `diary_keeper_03`, `diary_manya_01`,
`news_trees_listen`, `char_old_anya` (reserved for the finale convergence).

## Canon anchors used (verified in-repo, 2026-09-09)

- Prereq: `powered_by = [&"industrial"]` (`data/districts/district_substation.tres`);
  `map_position = (180, 300)`. Powers `power_station` — not a leaf.
- GDD §12.3: **Act III = D9–11** — substation is D10, and **the point of no return is
  entering D10** (the gatehouse / note_01 mark the threshold in prose only, never in UI).
- Enemies: `destroyer`, `watcher`, `hunter` (`enemy_pool.gd`) — **destroyer leads for the
  second district running**: no light reaction at all and breaks nearby streetlights while
  patrolling (`destroyer_3d.gd`). R5 keeps the chain's lesson: light is a spent consumable,
  never a tool; the hum (12 m) is the cue; the watcher takes the corridor (2 s stun then
  rage ×1.25 / 5 s, 15 m scream pulls the yard); the hunter holds the trench (rages ×1.3
  for 5 s when a beam leaves it).
- Themed loot: `district_loot.gd` BY_DISTRICT `substation = fuse, cable, transistor` →
  the repair chain itself is the theme (the building that routes the city's power pays out
  in parts), mirrored in the tables and `substation_fix_puzzle_01`/`_02`/`_03`.
- **No blueprint:** `BLUEPRINTS` canon is exactly four districts (residential, park, police,
  warehouses) — substation is not one of them, and GDD §9 lists no D10 craft (R7).
- Story doc: `doc_substation_guard` (welded door opened by itself at 03:00, darkness on the
  threshold, logged as a sensor trip) → extended, never copied, by `substation_note_01`
  (the guard's duplicate logbook).
- Puzzle: `puzzle_system.gd` `fuse_substation` (reward **coins 200**, `power_stage` 2)
  → the pad in `z_relay_room` (GG cell).
- Ambience details exist, header-verified by this PR: `substation_transformer_buzz` (0.0),
  `substation_arc_crackle` (5.8), `substation_cable_hum` (0.0); bed `substation_dark.ogg`
  exists (see AUDIO_COVERAGE for header numbers). Lit bed is a **real gap** — the G3
  one-liner is promoted to a full spec by this PR (spec only, not fabricated).
- Music: `music_manager.gd` maps substation → `music_ambient_dark.wav` (exists).
  `district_themes.gd` substation row is colour-only (no `"music"` key — same class as
  industrial/police/warehouses; no mismatch to flag). Theme accent `#f4f45d` is hotter
  than the ember token (STYLE_GUIDE §2); manifest keeps it off surfaces (small emissives
  only, same handling as industrial).
- Weather is **fog**; the yard reads through fog at every stage.

Consistency: zone ids shared across all three files; item ids ⊆ `data/items` (41); note ids
and fixed-spawn ids globally unique; referenced prop scenes and audio files exist
(spec-only `substation_lit.ogg` exempted); new textures ship in this PR.

## For CODE agent (wiring checklist)

1. `scenes/districts/substation.tscn` already exists with the sibling node contract —
   populate 10 zones per `prop_manifest.md`; `props/examine.tscn` ×8;
   `props/puzzle_3d.tscn` on the relay pad wired to `PowerSwitch` (`fuse_substation`);
   usable `props/streetlight_3d.tscn` ×11 across gatehouse/yard×2/relay/control/trench/
   bunk/boneyard/east gate/relay exterior/trench north. **Never** place a lamp in
   `z_switchgear_vault` (stay unlit at every stage — R8) or in/around `z_arc_cage`
   (never entered, never lit — R8; the dead flood outside the mesh is a prop, not a lamp).
2. Loot rolls keyed by `DistrictData.Stage`; enforce R1 (chain solvable in DARK: 2 cable /
   2 fuse / 2 transistor + vault key, no lockpick), R2 (fuse/transistor never in DARK rolls;
   molotov from PARTIAL, noise_bomb from STREETS), R6 (scripted caches never empty),
   R7 (**no blueprint id may spawn here — substation has no BLUEPRINTS row**).
3. Lock `z_switchgear_vault` with `substation_fix_key_01` (control-room desk drawer,
   unlocked). Lock `z_arc_cage` with **no key anywhere** (examine through the mesh only).
4. Lore notes → existing pickup flow; add the `substation` id list to
   `DistrictLoot.LORE_DOCS`: `substation_note_01` … `substation_note_08`.
5. Destroyer-led patrol: destroyer on the transformer yard + boneyard edge (it WILL break
   relit floods — intended, do not guard against it); hunter in the cable trench; watcher
   on the relay/control corridor. The DARK chain must never require light, combat or a
   chase (R1).
6. New textures available: `tiles/substation_floor_lit.png` / `substation_wall_lit.png`
   (§4.1-verified) — follow the shipped `_lit` convention for
   `district_grading.gd::_apply_ground`.
7. Map wiring note: substation is the map's row-2 middle — the industrial south-gate road
   enters at `D`, the sealed east gate (`?`) opens toward `power_station` at FULL.

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE runs them. This pass validated statically: JSON
parse, id cross-refs, path existence, Ogg header parse, image metrics.)

## For LOCALE agent — add to all 13 locales

`LORE_SUBSTATION_<NN>_TITLE` / `LORE_SUBSTATION_<NN>_TEXT`, NN ∈ 01–08 → **16 keys**;
en source = the `en` fields in `content/districts/substation/lore_notes.json`.

```
LORE_SUBSTATION_01_TITLE  LORE_SUBSTATION_01_TEXT
LORE_SUBSTATION_02_TITLE  LORE_SUBSTATION_02_TEXT
LORE_SUBSTATION_03_TITLE  LORE_SUBSTATION_03_TEXT
LORE_SUBSTATION_04_TITLE  LORE_SUBSTATION_04_TEXT
LORE_SUBSTATION_05_TITLE  LORE_SUBSTATION_05_TEXT
LORE_SUBSTATION_06_TITLE  LORE_SUBSTATION_06_TEXT
LORE_SUBSTATION_07_TITLE  LORE_SUBSTATION_07_TEXT
LORE_SUBSTATION_08_TITLE  LORE_SUBSTATION_08_TEXT
```

## Remaining districts

`power_station` (final).
