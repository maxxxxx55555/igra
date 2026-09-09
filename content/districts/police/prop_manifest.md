# Prop Manifest — District `police` (district 7)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §4.3 (prereqs must be FULL), §9 (D7
interrogation = strobe workbench *location*, no new item id), §12.3 (Act II chain
territory; Architect reveal stays on the hospital branch), §14 perf.
Scene to wire: `scenes/districts/police.tscn` (same node contract as siblings:
`StreetBuilder`, `Props`, `PowerSwitch`, `EmissiveWindows`, `DistrictTrigger`).
Opens at **park FULL** (`district_police.tres` `powered_by = [&"park"]`).
Powers `industrial` (with `warehouses`) — not a leaf.
Enemies (canon, `enemy_pool.gd`): `watcher`, `hunter`, `destroyer` — **destroyer leads**.
Theme (`district_themes.gd`): primary `#4a4a6a`, accent `#5d5dc8`, sky `#0a0a11`,
ambient `#12121c` — cold station blue. Palette caution (STYLE_GUIDE §2): `#5d5dc8` is
hotter/more saturated than the teal info token; keep it on *small* emissive accents
only (duty-desk lamp, radio LED) — never on surfaces. All new art in this pass stays
inside the token set.
Puzzle canon: `puzzle_system.gd` `transformer_police` (reward 2 battery, `power_stage` 2).

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference the `DistrictLayouts` police grid
advisory-style: `####` two wings, `GG` transformer pad, `k` holding cells, `K` front
desk, `L` courtyard lamp, `b` evidence, `m` armory, `T` radio/dispatch, `o`
interrogation, `H` south public entrance.

## Zone map (9 zones)

```
        [west wing]                         [east wing]
 z_generator_room (GG)                      z_holding_cells (k)
 z_front_desk (K)      z_courtyard (L)      z_evidence_room (b)
 z_radio_room (T)      z_armory (m)         z_interrogation (o)
        z_station_front (H, from park road)
```

Everything except the front lot and the lamp court is interior. The destroyer patrols
the east wing (cells → evidence → interrogation); light does not slow it.

## Per-zone plan

### z_station_front — public entrance from the park road, SAFE-ish (H cell)
- Props: station steps, dead blue lamp over the door, barrier gate, notice board,
  `trash_bin` ×2, 1 flickering `props/streetlight_3d.tscn` on the lot pole.
- Pickups: fixed `police_fix_exit_01` (3× battery), `police_fix_defense_01` (2× molotov,
  STREETS+). No rolled loot (safe-start rule).
- Stage behavior: DARK = flicker; STREETS+ the lot pole steadies; FULL the door lamp
  takes a low-energy `#5d5dc8` LED (the district's only hot accent, small).
- Ambience: `police_siren_tail.ogg` (0.0 dB) strongest here — a siren that never
  finishes starting.

### z_front_desk — lobby / sergeant's desk (K cell)
- Props: reception desk with blotter (`props/examine.tscn` → `police_note_01`), open
  duty log (`props/examine.tscn` → `police_note_04`), waiting-row chairs, `desk_drawer`,
  stopped wall clock, dead security monitor.
- Pickups: fixed `police_fix_key_01` (evidence key); 1 rolled `desk_drawer`.
- Stealth: the hub. Short sightlines into both wings; poor loot.

### z_courtyard — internal lamp court (L cell)
- Props: one usable `props/streetlight_3d.tscn` (the station's yard flood — the object
  `police_note_04` / `_06` keep talking about), chain-link, bench, `filing_cabinet`.
- Pickups: 1 rolled `filing_cabinet`. No fixed cache.
- Stage behavior: DARK = dead; PARTIAL = flicker (the flood that came on with the
  switch off); STREETS+ steady; at FULL the Keeper has notionally taken the transformer
  — keep the lamp lit anyway (the player restored it) but leave the empty bolt holes
  on the cage as the note's payoff.
- Ambience: `police_boots_concrete.ogg` (2.4 dB) — a patrol that isn't there.

### z_holding_cells — east-wing cells (k cell)
- Props: four cell fronts (`surfaces/cell_bars_512.png`, generated this pass), bunk
  frames, observation slit with the photo (`props/examine.tscn` → `police_note_02`),
  `cell_bunk` containers ×2. No lamps in this wing (note 08 rule 1) — do not place a
  `streetlight_3d` here at any stage.
- Pickups: fixed `police_fix_med_01` (2× medkit); 1 rolled `cell_bunk`.
- Stealth: destroyer's home. Single corridor, no cover except the cells themselves.
  Light is not a weapon here (R5).
- Ambience: boots at −6 dB; radio static bleed from the west wing.

### z_evidence_room — seized-property lockers (b cell, locked)
- Props: locker bank (`surfaces/school_lockers_512.png` reused, steel), locker 12 with
  the photo (`props/examine.tscn` → `police_note_05`, PARTIAL+), `evidence_locker` ×2,
  tagged lamp-heads as debris (existing streetlight mesh, unlit).
- Pickups: fixed `police_fix_puzzle_03` (2× transistor); rolls non-empty by R6.
- Lock: `police_fix_key_01` from the desk. Single door — rich, dead-end (R5).

### z_armory — stripped cage (m cell)
- Props: empty rifle racks (no firearm pickups — R4), `armory_cage` ×2, powder tins,
  casing trays. Door open; the cage itself is the container.
- Pickups: fixed `police_fix_armory_01` (2× gunpowder), `police_fix_armory_02` (3× case);
  rolls non-empty by R6.
- Fire/powder rule: this is the only legal gunpowder location (R8).

### z_interrogation — interrogation 2 (o cell)
- Props: metal table, two chairs, wall board with the rules (`props/examine.tscn` →
  `police_note_08`, FULL only), `filing_cabinet`, one desk lamp that *pulses* from
  STREETS (GDD §9 strobe location — flavour only; no strobe blueprint id exists in
  `data/items`).
- Pickups: fixed `police_fix_blueprint_01` (`blueprint_backpack_capacity`); 1 rolled
  `filing_cabinet`.
- Purpose: D7 schematic payoff + the district's last word. Unlocked in DARK so R7 holds.

### z_generator_room — transformer pad (GG cell)
- Props: `props/puzzle_3d.tscn` pad wired to `PowerSwitch` (this is `transformer_police`),
  `surfaces/generator_metal_512.png` / `surfaces/fusebox_512.png` panel, `tool_cage`,
  release form clipped to the cage (`props/examine.tscn` → `police_note_06`, STREETS+),
  empty bolt holes where the yard-flood transformer was taken.
- Pickups: fixed `police_fix_puzzle_01` (2× cable); 1 rolled `tool_cage`.
- Powder rule: no gunpowder in this room (R8).
- Ambience: `substation_cable_hum.ogg` at −12 dB once powered (existing file reused).

### z_radio_room — dispatch (T cell)
- Props: radio rack, handset, cassette deck with the log (`props/examine.tscn` →
  `police_note_03`, PARTIAL+; `police_note_07` STREETS+), `radio_shelf`, dead CRT,
  one `#5d5dc8` LED that stays on in DARK (residual, not a light source).
- Pickups: fixed `police_fix_puzzle_02` (2× fuse); 1 rolled `radio_shelf`.
- Ambience: `police_radio_static.ogg` (4.9 dB) loudest here.

## Streetlight & stage-state summary

| Stage | Lights lit (of 5 usable) | Warm points | Ambience shift |
|-------|--------------------------|-------------|----------------|
| DARK (0)    | 0 + lot flicker     | radio LED only (cold)        | police_dark bed + siren tail + radio static + boots |
| PARTIAL (1) | 2 (lot + court flood flicker) | desk lamp cold     | radio static drops 2 dB; boots stay |
| STREETS (2) | 4 (+ desk, door)    | interrogation pulse lamp     | siren tail thins; court flood steadies |
| FULL (3)    | 5 + door LED        | pulse lamp + door LED        | warm lit layer — `police_lit.ogg`, spec in docs/AUDIO_COVERAGE.md |

`z_holding_cells` stays unlit at every stage (note 08 rule 1 / R5). Don't let a global
relight pass overwrite it.

## Art / audio gaps

1. Lit tile twins `tiles/police_floor_lit.png` / `police_wall_lit.png` —
   **filled by this pass** (generated, §4.1 numeric test recorded in `docs/ASSET_LICENSES.md`).
2. Cell-bar prop surface `surfaces/cell_bars_512.png` — **filled by this pass**.
3. Evidence locker / rifle-rack meshes — placeholder boxes until art lands (no blocking
   dependency; existing locker/cage props cover the zones meanwhile).
4. Audio `districts/police_lit.ogg` — **real gap**, full spec in
   `docs/AUDIO_COVERAGE.md` (not fabricated here). Dark bed and all 3 detail one-shots
   exist and were header-verified this pass.
