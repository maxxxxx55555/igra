# Prop Manifest — District `warehouses` (district 8)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §4.3 (prereqs at FULL), §9 (D8 portable
workbench *location* — no new blueprint id; the district's real schematic is
`blueprint_backpack_slots` per `district_loot.gd`), §12.3 (Act II chain territory; the
Project Architect set is hospital-gated and therefore guaranteed at arrival — used at
STREETS+ only), §14 perf.
Scene to wire: `scenes/districts/warehouses.tscn` (already scaffolded with the sibling
node contract: `StreetBuilder`, `PowerSwitch`, `DistrictTrigger`, `EmissiveWindows`,
`Props`). Opens at **hospital FULL** (`district_warehouses.tres` `powered_by = [&"hospital"]`).
Powers `industrial` (with `police`) — **not a leaf**.
Enemies (canon, `enemy_pool.gd`): `crawler`, `destroyer`, `hunter` — **crawler leads**:
1.5× speed, 6 m sight, flinches out of light for 1 s (GDD §6.2). The flashlight is a
disengage tool here, not a weapon; the destroyer (no light reaction) holds the cold annex.
Theme (`district_themes.gd`): primary `#5a4a3a` (umber), accent `#e85d3a` (ember — STYLE_GUIDE
§2: hotter than the ember token; keep it to small emissives only, never on surfaces),
sky `#100d0a`, fog `#1a140f`, weather **fog**.
Puzzle canon: `puzzle_system.gd` `switch_warehouses` (reward 150 coins, `power_stage` 2).

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference the `DistrictLayouts` warehouses grid
advisory-style: `GG` feeder room, `K` foreman office, `L` yard flood, `s`/`b` rack
floors, `c` quarantine cage, `f` belt/sorter bay, `T` break room, `D` dock gate entry
(from the hospital road), `?` east gate (sealed; the future road to `industrial`).

## Zone map (9 zones)

```
        [west shed]                          [east shed]
 z_switch_room (GG)      z_loading_yard (L, between)    z_east_hall (s/racks)
 z_west_hall (f/belt)    <- trailer bay doors ->        z_cold_storage (b, never lit)
 z_foreman_office (K)    z_dock_gate (D, entry          z_returns_cage (c, locked)
 z_break_room (T)         from hospital road, south)    (? = sealed east gate)
```

Two shed halls face each other across an open loading yard. The sorter belt runs the
length of the west hall and its tail disappears into the quarantine cage wall in the
east shed — the district's one uncanny through-line (notes 04/06/07/08).

## Per-zone plan

### z_dock_gate — entry from the hospital road, SAFE-ish (D cell)
- Props: gatehouse booth with the gate log (`props/examine.tscn` → `warehouses_note_01`),
  barrier arm, road sign "Склады →" facing the hospital road, chain-link, one lamp on the
  booth, `cargo_crate` ×1, dock canopy edge.
- Pickups: fixed `warehouses_fix_exit_01` (3× battery). No rolled loot (safe-start rule).
- Stage behavior: DARK = booth lamp dead; PARTIAL+ booth lamp takes a low warm `#c9a24a`
  energy; the barrier stays down until the district opens (trigger).
- Ambience: `warehouses_chain_rattle.ogg` (2.1 dB) loudest here — chains the yard owns.

### z_loading_yard — the open yard between the sheds (L cell)
- Props: two yard floods on poles (usable `props/streetlight_3d.tscn` ×2 — the floods of
  `warehouses_note_02`), bay doors 1–6 with one trailer still docked at bay four (ramp up,
  empty — the trailer the note photographed is gone), `parts_bin` at the flood breaker
  box, `dumpster`, pallet jacks, fog.
- Pickups: fixed `warehouses_fix_puzzle_02` (2× fuse, breaker box), `warehouses_fix_defense_01`
  (2× molotov, STREETS+, dumpster); 1 rolled `parts_bin`.
- Stage behavior: DARK = floods dead (breaker D off — note_02's payoff: they are only off
  *now*); PARTIAL = one flood steadies (the breaker's own circuit); STREETS = both floods
  + dock canopy; FULL = the whole yard warm through the fog.
- Ambience: `warehouses_chain_rattle.ogg` (2.1), `warehouses_cargo_impact.ogg` (0.0) as
  isolated one-shots from the bays, `warehouses_forklift_distant.ogg` (0.0) faint.

### z_west_hall — main rack floor of the west shed (f/belt cell)
- Props: rack rows A–F (pallet racking), pallet stacks, the sorter belt along the north
  wall running toward the quarantine wall, high-bay lamp pair (usable ×2), `pallet_rack`
  containers ×3, banding-offcuts debris.
- Pickups: fixed `warehouses_fix_stores_01` (3× scrap, rack A); 2 rolled `pallet_rack`.
- Stealth: crawler country. Rack aisles break the 120° cone and the 6 m sight — stand
  still in an aisle and it passes; run and it catches you (R5).
- Ambience: `warehouses_metal_creak.ogg` (0.0) strongest here; belt stays silent at every
  stage — it is never a sound cue, it is the anomaly (notes 03/04).

### z_east_hall — rack floor of the east shed (s/b cell)
- Props: rack rows B–E with dead stock, the quarantine wall at the south end (the belt
  tail disappears into it), cold-annex door at the north end, high-bay lamp pair (usable
  ×2), `pallet_rack` containers ×2, un-numbered drum lot behind rack B.
- Pickups: fixed `warehouses_fix_stores_02` (1× cable, the un-numbered drum); 1 rolled
  `pallet_rack`.
- Stealth: hunter territory near the cold door; keep to the rack shadows.
- Ambience: `warehouses_forklift_distant.ogg` (0.0) — a forklift that is never there.

### z_cold_storage — cold annex, north of the east hall (b cell, **never relit — R8**)
- Props: insulated door with seal, pallet of unopened quarantine crates (one holds the
  letter: `props/examine.tscn` → `warehouses_note_06`, STREETS+), racking, frost on the
  steel, the district's destroyer holds the room.
- Pickups: 1 rolled `pallet_rack` (poor — the destroyer's room pays badly).
- No lamp in this room at any stage (R8); the door seal lamp lives outside. The destroyer
  does not react to light, so the room must never *need* light to be read.
- Ambience: dead air; `warehouses_metal_creak.ogg` at −8 dB from the far side of the door.

### z_returns_cage — quarantine cage annex, south of the east hall (c cell, locked)
- Props: mesh cage walls, `returns_cage` shelving, the return tag on the mesh
  (`props/examine.tscn` → `warehouses_note_05`, PARTIAL+), viewing slit in the cage door,
  the belt tail entering the wall above the cage.
- Pickups: fixed `warehouses_fix_puzzle_03` (2× transistor); rolls non-empty by R6.
- Lock: `warehouses_fix_key_01` from the foreman's desk. Short corridor, single door —
  the DARK solvability room (R1). Never lit (R8); read by corridor spill.
- Stealth: crawlers wander the corridor; the slit lets you confirm the cage before you
  commit to the lock.

### z_foreman_office — mezzanine office over the west hall (K cell)
- Props: desk with the pocket book (`props/examine.tscn` → `warehouses_note_04`), wall
  clock stopped at 02:00 (the hour the belt runs), `steel_locker` with the shift records,
  window looking out over the yard flood.
- Pickups: fixed `warehouses_fix_key_01` (cage key, unlocked desk drawer),
  `warehouses_fix_blueprint_01` (`blueprint_backpack_slots`, locker); 1 rolled
  `office_desk`.
- Purpose: D8 schematic payoff + the key-chain start. Reachable in DARK so R1/R7 hold.
- Stage behavior: office lamp usable from FULL only (the desk is read by window spill
  before that).

### z_break_room — shift room behind the office (T cell)
- Props: steel lockers, table, dead radio, cassette player with the loader's tape
  (`props/examine.tscn` → `warehouses_note_07`, STREETS+), `steel_locker` ×1 rolled +
  the first-aid locker.
- Pickups: fixed `warehouses_fix_med_01` (2× medkit); 1 rolled `steel_locker`.
- Ambience: quietest zone; the belt's counting is audible through the wall at −12 dB —
  a rhythm that is not quite a rhythm.

### z_switch_room — feeder room, north end of the west hall (GG cell)
- Props: `props/puzzle_3d.tscn` pad wired to `PowerSwitch` (this is `switch_warehouses`),
  feeder map on the wall (district spurs drawn in pencil; the east-gate photo taped to the
  door: `props/examine.tscn` → `warehouses_note_08`, FULL only), control desk with the
  recorder (`props/examine.tscn` → `warehouses_note_03`, PARTIAL+), `tool_chest`, cable
  runs to the drum lot.
- Pickups: fixed `warehouses_fix_puzzle_01` (2× cable); 1 rolled `tool_chest`.
- Ambience: `substation_cable_hum.ogg` at −12 dB once powered (existing file reused, no
  new audio).

## Streetlight & stage-state summary

| Stage | Lights lit (of 10 usable) | Warm points | Ambience shift |
|-------|---------------------------|-------------|----------------|
| DARK (0)    | 0 (breaker D off — note_02's now) | none; fog holds the yard        | warehouses_dark bed + creak + chain rattle + distant forklift |
| PARTIAL (1) | 2 (dock canopy + yard flood A)    | flood A through the fog         | forklift thins; creak stays |
| STREETS (2) | 5 (+ yard flood B, booth, west-hall pair) | belt tail visible at the quarantine wall | cargo_impact gains weight; cable hum starts in the feeder room |
| FULL (3)    | 10 (east hall, office, break room added) | office window + full yard       | warm lit layer — `warehouses_lit.ogg`, spec in docs/AUDIO_COVERAGE.md |

`z_cold_storage` and `z_returns_cage` stay unlit at every stage (R8). The sorter belt
never lights and never makes its own sound — both would turn the anomaly into wallpaper.

## Art / audio gaps

1. Lit tile twins `tiles/warehouses_floor_lit.png` / `warehouses_wall_lit.png` —
   **filled by this pass** (derived from the dark twins, §4.1 numbers in
   `docs/ASSET_LICENSES.md`). The shipped dark floor carried a 3 px dark frame on its top
   and left edges (wrap seam 18.8 vs the 3.8–4.4 house range) — **edge-repaired in this
   pass** (1,467 px mirrored from the interior; seam now 3.85); the lit twin was derived
   from the repaired dark so the pair stays geometry-locked.
2. Warehouse prop faces — spec only, non-blocking (placeholder boxes / existing surfaces
   cover the zones meanwhile, mirroring police's locker/rifle-rack note):
   - `surfaces/pallet_rack_512.png` — racking face for the A–F rows (steel uprights +
   brass `#c9a24a` load-beam tips as the only accent; matte, unlit).
   - `surfaces/cargo_crate_512.png` — crate face for the dock staging (wood + banding;
   stencil-free, no text).
   - Optional: sorter belt visual (low conveyor mesh using `metal_rust_512.png`; no
   motion at any stage — it is a corpse of a machine).
3. Audio `districts/warehouses_lit.ogg` — **real gap**, full spec in
   `docs/AUDIO_COVERAGE.md` G2g (not fabricated here). Dark bed and all 4 detail one-shots
   exist and were header-verified this pass (bed 1 ch/44.1 kHz/36.000 s; one-shots
   1 ch/44.1 kHz/30.000 s).
