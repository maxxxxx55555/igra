# Content Handoff — District `industrial` (district 9)

Task: district-level content per GDD §4.1 canon order (… → warehouses → **industrial**).
Name verified directly against `docs/GDD.md` §4.1 and `data/districts/district_industrial.tres`.
Scope respected: only `content/**`, `assets/textures/**`, `assets/audio/**` (header
verify + spec only) and `docs/**`. No `*.gd`, `*.tscn`, `*.tres`, `tools/`, `locales/`,
`data/`, root `*.md`. Frozen docs untouched.

## Deliverables

| File | What it is |
|------|-----------|
| `content/districts/industrial/lore_notes.json` | 8 notes (4 documents, 2 photos, 2 audio logs), stage-gated 0–3, `world_refs` ids |
| `content/districts/industrial/item_spawns.json` | 4 stage tables + 10 fixed spawns + 9 container modifiers + rules R1–R8 |
| `content/districts/industrial/prop_manifest.md` | 10-zone placement plan, stage-state table, art/audio gaps |
| `docs/CONTENT_DISTRICT_INDUSTRIAL.md` | this handoff |

Also in this PR: the industrial asset pass (2 lit tile twins, §4.1-verified, ledgered in
`docs/ASSET_LICENSES.md` — the shipped dark twins were seam-probed clean first, no repair
needed), the `industrial_lit.ogg` full spec appended to `docs/AUDIO_COVERAGE.md` (G2h), and
the district-9 row + full re-run in `docs/CONTENT_PIPELINE_AUDIT.md`.

## The two-parent convergence closure (computed, double-check this first)

`industrial.powered_by = [&"warehouses", &"police"]` — GDD §4.3 requires **every** prereq at
FULL, so industrial opens only when BOTH parents are done. The guaranteed history at arrival
is therefore the **union of both branches' transitive closures**, each walked to FULL:

- **warehouses branch:** warehouses → hospital → residential → suburbs
- **police branch:** police → park → suburbs
- **Union (guaranteed at arrival): `suburbs`, `residential`, `park`, `hospital`,
  `warehouses`, `police` — six districts, all stages.**

Every world id gated on any of those six is safe here regardless of its own `min_stage`.
**NOT guaranteed: `school`, `gas_station`** (leaves of the `powered_by` graph — neither is an
ancestor of either parent; no id is gated on them anyway, but the pack never leans on
school/gas_station content), **and `substation`, `power_station`** (descendants, not
ancestors — so the Act III broadcasts `radio_02_grid_crew_relay` / `radio_03_keeper_reversal`
must never spawn here even though industrial is D9 / the first Act III district: GDD §12.3's
act boundary moves the story, the world-bible reveal gates stay absolute).

This is the **first district where the Act II Project Architect set (hospital-gated, via the
warehouses branch) and the Keeper/radio-voice set (park-gated, via the police branch) are
simultaneously guaranteed** — notes 04–08 are built as the convergence payoff: the works
ledger shows the Keeper's order 14,208 passing through the same dock that shipped the grid
(14,207), and the same works order file shows where the Architect's backward-meter drums were
wound and shipped. Council decision (skill `council`, logged): convergence-harvest — reference
both threads, zero illegal ids, Act III foreshadowing stays in prose (note_08's "past the
substation gate nobody walks back out"), never in journal ids.

### world_refs reachability (computed `powered_by` union closure)

23 `world_refs`, all inside the six-district union:

- suburbs-gated: `hist_blackout_night`, `faction_city_power`, `news_rolling_outages`,
  `char_marat`, `char_grid_crew_recorder`, `faction_grid_crew` (notes 01/03/08)
- residential-gated: `char_superintendent`, `news_meter_anomaly` (note 05)
- park-gated: `char_keeper`, `faction_keepers`, `hist_grid_built`, `hist_keeper_reversal`
  (note 04), `char_babka_manya`, `char_petrov`, `hist_crew_walk_park` (note 07),
  `char_radio_voice`, `radio_01_power_station`, `hist_radio_call` (note 08)
- hospital-gated (Act II Architect set, paced `min_stage >= 2` matching their own STREETS
  gate and the warehouses precedent): `hist_project_architect` (05), `char_architect`,
  `faction_project_architect`, `news_architect_denied` (06)

**Not referenced:** school/gas_station branch content, all Act III ids
(`radio_02_grid_crew_relay`, `radio_03_keeper_reversal`), `hist_present_day`,
`hist_evacuation_arena`, `diary_*` (kept in reserve for substation/power_station; the
convergence does not need them).

## Canon anchors used (verified in-repo, 2026-09-09)

- Prereq: `powered_by = [&"warehouses", &"police"]` (`data/districts/district_industrial.tres`);
  `map_position = (60, 300)`. Powers `substation` — not a leaf.
- GDD §12.3: **Act III = D9–11** — industrial is the act opener; point of no return is
  entering D10 (the south gate / note_08 mark the threshold in prose only).
- Enemies: `destroyer`, `hunter`, `watcher` (`enemy_pool.gd`) — **destroyer leads**, and
  unlike every previous lead it has **no light reaction at all and breaks nearby
  streetlights while patrolling** (`destroyer_3d.gd`). R5 adapts the chain's lesson:
  light is a spent consumable here, never a tool; the hum (12 m) is the cue; the hunter
  rages ×1.3 for 5 s when a beam leaves it; the watcher rages ×1.25 after its 2 s stun and
  its 15 m scream pulls the floor.
- Themed loot: `district_loot.gd` BY_DISTRICT `industrial = fuse, transistor, gear, metal`
  → the plant-as-parts-bin theme the notes lean on (`industrial_note_03` counts the stores
  in-world), mirrored in the tables and `industrial_fix_stores_01`/`_02`.
- **No blueprint:** `BLUEPRINTS` canon is exactly four districts (residential, park, police,
  warehouses) — industrial is not one of them. GDD §9 lists a "Battery L2" craft at
  "D9 цех"; there is no `blueprint_battery_l2` id in `data/items/*.tres` — same treatment as
  police's D7 strobe and warehouses' D8 workbench: location flavour only, no invented item
  (R7).
- Story doc: `doc_factory_log` (Factory #9 shift log — 22:00 hum from the generator, 23:15
  light in workshop B flickering) → extended, never copied, by `industrial_note_02` (the
  23:15 photograph), `_01` (the time cards) and `_03` (the crew's stores check).
- Puzzle: `puzzle_system.gd` `generator_industrial` (reward **2× medkit**, `power_stage` 2)
  → the pad in `z_generator_hall` (GG cell).
- Ambience details exist, header-verified this pass: `industrial_machinery_drone` (4.0 dB),
  `industrial_pipe_hiss` (0.0), `industrial_steam_vent` (0.0), `industrial_vent_rattle`
  (4.5) — all 1 ch/44.1 kHz/30.000 s; bed `industrial_dark.ogg` 1 ch/44.1 kHz/**33.994 s**
  (the only district bed off the 36.000 s house contract — real finding, recorded in
  AUDIO_COVERAGE G2h with both readings; the 12-bar theme canon at 85 bpm = 33.88 s ≈
  shipped length). Lit bed is a **real gap** — full spec in AUDIO_COVERAGE G2h (spec only,
  not fabricated).
- Music: `music_manager.gd` maps industrial → `industrial.wav` (exists). `district_themes.gd`
  industrial row is colour-only (no `"music"` key — same class as police/warehouses; no
  mismatch to flag). Theme accent `#e85d3a` is hotter than the ember token (STYLE_GUIDE §2);
  manifest keeps it off surfaces (small emissives only, same handling as warehouses).
- Weather is **fog**; the plant reads through fog at every stage.

Consistency: zone ids shared across all three files; item ids ⊆ `data/items` (41); note ids
and fixed-spawn ids globally unique; referenced prop scenes and audio files exist
(spec-only `industrial_lit.ogg` exempted); new textures ship in this PR.

## For CODE agent (wiring checklist)

1. `scenes/districts/industrial.tscn` already exists with the sibling node contract —
   populate 10 zones per `prop_manifest.md`; `props/examine.tscn` ×8;
   `props/puzzle_3d.tscn` on the feeder pad wired to `PowerSwitch`
   (`generator_industrial`); usable `props/streetlight_3d.tscn` ×11 across dock/floor/
   line-north/generator/catwalk/stores×2/workshop/locker/south gate. **Never** place a
   lamp in `z_switchgear_room` or the assembly-line grease pit (stay unlit at every
   stage — R8).
2. Loot rolls keyed by `DistrictData.Stage`; enforce R1 (chain solvable in DARK: 2 cable /
   2 fuse / 2 transistor + desk key, no lockpick), R2 (fuse/transistor never in DARK rolls;
   molotov from PARTIAL, noise_bomb from STREETS), R6 (scripted caches never empty),
   R7 (**no blueprint id may spawn here — industrial has no BLUEPRINTS row**).
3. Lock `z_switchgear_room` with `industrial_fix_key_01` (foreman's catwalk desk drawer,
   unlocked).
4. Lore notes → existing pickup flow; add the `industrial` id list to
   `DistrictLoot.LORE_DOCS`: `industrial_note_01` … `industrial_note_08`.
5. Destroyer-led patrol: destroyer on the factory floor and the line pit (it WILL break
   relit high-bays — intended, do not guard against it); hunter in the stores yard;
   watchers by the switchgear corridor. The DARK chain must never require light, combat
   or a chase (R1).
6. New textures available: `tiles/industrial_floor_lit.png` / `industrial_wall_lit.png`
   (§4.1-verified) — follow the shipped `_lit` convention for
   `district_grading.gd::_apply_ground`.
7. Map wiring note: industrial is the map's row-2 start — both parent roads
   (warehouses east gate, police south) should read on the district trigger.

Gates after wiring (headless, exit 0): compile, signal arity, i18n, asset check.
(Unavailable in this sandbox — CODE runs them. This pass validated statically: JSON
parse, id cross-refs, path existence, Ogg header parse, image metrics.)

## For LOCALE agent — add to all 13 locales

`LORE_INDUSTRIAL_<NN>_TITLE` / `LORE_INDUSTRIAL_<NN>_TEXT`, NN ∈ 01–08 → **16 keys**;
en source = the `en` fields in `content/districts/industrial/lore_notes.json`.

```
LORE_INDUSTRIAL_01_TITLE  LORE_INDUSTRIAL_01_TEXT
LORE_INDUSTRIAL_02_TITLE  LORE_INDUSTRIAL_02_TEXT
LORE_INDUSTRIAL_03_TITLE  LORE_INDUSTRIAL_03_TEXT
LORE_INDUSTRIAL_04_TITLE  LORE_INDUSTRIAL_04_TEXT
LORE_INDUSTRIAL_05_TITLE  LORE_INDUSTRIAL_05_TEXT
LORE_INDUSTRIAL_06_TITLE  LORE_INDUSTRIAL_06_TEXT
LORE_INDUSTRIAL_07_TITLE  LORE_INDUSTRIAL_07_TEXT
LORE_INDUSTRIAL_08_TITLE  LORE_INDUSTRIAL_08_TEXT
```

## Remaining districts

`substation → power_station` (final).
