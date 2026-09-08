# Prop Manifest — District `gas_station` (district 6)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §4.3 (prereqs must be FULL), §14 perf.
Scene to wire: `scenes/districts/gas_station.tscn` (same node contract as siblings:
`StreetBuilder`, `Props`, `PowerSwitch`, `EmissiveWindows`, `DistrictTrigger`; note
`street_builder.gd` already references a `GasGenerator` instance for this district).
Opens at **park FULL** (`district_gas_station.tres` `powered_by = [&"park"]`).
Enemies (canon, `enemy_pool.gd`): `hunter`, `shadow`, `crawler` — **hunter leads**.
Theme (`district_themes.gd`): primary `#5a4a3a`, accent `#e85d3a`, sky `#100d0a`,
ambient `#1a140f` — the warmest, dirtiest palette in the game (sodium + rust + fuel film).
Puzzle canon: `puzzle_system.gd` `fuse_gas_station` (reward 125 coins, `power_stage` 2).

Palette caution (STYLE_GUIDE §2): the district accent `#e85d3a` is hotter than the ember
token `#b4452f`. Keep it on *small* emissive accents only — the price totem, the drum fire,
the danger decals — never on surfaces. All new art in this pass stays inside the token set.

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference the `DistrictLayouts` gas_station grid
advisory-style: `s s` pump islands, `GG` generator pad, `K` kiosk, `L` lamp, `T` tanker,
`b` shop, `f` service bay, `?` park-road entry, `o` outbuilding/camp, `C` east exit.

## Zone map (9 zones)

```
        z_generator_yard (GG)        z_shop (b)
 z_road_queue (slip road)   z_pump_island (s s)   z_service_bay (f)
        z_forecourt (?, from park)   z_tanker (T)
        z_scavenger_camp (o)                       z_exit_east (C)
```

## Per-zone plan

### z_forecourt — entry from the park road, SAFE-ish
- Props: canopy skeleton (glass gone), price totem with dead digits, kiosk post with the
  scavenger's second page (`props/examine.tscn` → `gas_station_note_01`), 1 flickering
  `props/streetlight_3d.tscn` on the canopy column, `trash_bin`.
- Pickups: fixed `gas_station_fix_exit_01` (3× battery). No rolled loot (safe-start rule).
- Stage behavior: DARK = flicker; STREETS+ steady; at FULL the price totem lights with two
  digits dead — one small `#e85d3a` accent, the district's only hot emissive.
- Ambience: `gas_station_sign_buzz.ogg` (0.0 dB) strongest here; `gas_station_car_pass.ogg`
  (2.2 dB) as a distant road event on a 60–120 s timer.

### z_pump_island — the two pump rows (s cells)
- Props: 6 pumps (`surfaces/fuel_pump_512.png`, generated this pass), hose loops on the
  ground, cashier kiosk with the clipboard (`props/examine.tscn` → `gas_station_note_04`),
  `till_drawer` container in the kiosk, spill decals.
- Pickups: fixed `gas_station_fix_puzzle_02` (2× fuse); 1 rolled `till_drawer`.
- Ambience: `gas_station_pump_hum.ogg` (0.0 dB) — canon detail bed, but here it is the
  *joke that isn't funny*: the pumps have no power (see `gas_station_note_04`). Keep it
  quiet in DARK and let it rise a little at PARTIAL.
- Fire rule: no open-flame item spawns here (item_spawns R7).

### z_shop — station shop and till (b cell)
- Props: toppled shelving (`shop_shelf` container ×2), coffee machine, fridge wall with
  `EmissiveWindows`-style dead glass, counter with the recorder (`props/examine.tscn` →
  `gas_station_note_03`, PARTIAL+), `till_drawer`.
- Pickups: fixed `gas_station_fix_key_01` (service-bay key), `gas_station_fix_craft_01`
  (3× bottle); 1 rolled `shop_shelf`.
- Stealth: shelving rows are the district's only interior cover; short sightlines, poor
  loot — the quiet half of R5.

### z_service_bay — workshop / wash bay (f cell, locked)
- Props: roller door (locked, `gas_station_fix_key_01`), inspection pit, `tool_cage` ×2,
  compressor, requisition pad on the bench (`props/examine.tscn` → `gas_station_note_06`,
  STREETS+), oil drums using `surfaces/metal_rust_512.png`.
- Pickups: fixed `gas_station_fix_puzzle_03` (2× transistor); 1 rolled `tool_cage`.
- Purpose: key-chain payoff + the Keeper's requisition — the first hard evidence in this
  branch that the old man is dismantling the grid on purpose.

### z_tanker — tanker apron (T cell)
- Props: articulated tanker with fill hoses out, chocked wheels, cab with the photo
  (`props/examine.tscn` → `gas_station_note_05`, PARTIAL+), `fuel_locker` container,
  underground-tank hatches with lifting keys still in them.
- Pickups: fixed `gas_station_fix_fuel_01` (2× gas_canister); rolls non-empty by R6.
- Fire rule: no open-flame item spawns (R7).
- Stealth: the apron is open and gravelled — crossing it fast is the loudest thing in the
  district (`gas_station_gravel_crunch.ogg`).

### z_road_queue — slip road, the abandoned queue
- Props: 9 cars nose to tail (existing debris/vehicle props), doors open, boots open
  (`car_trunk` containers ×2), the canopy sign frame with the photo
  (`props/examine.tscn` → `gas_station_note_02`), third car with the cassette
  (`props/examine.tscn` → audio_log `gas_station_note_07`, STREETS+).
- Pickups: fixed `gas_station_fix_defense_01` (2× molotov, STREETS+); 2 rolled `car_trunk`.
- Ambience: `gas_station_car_pass.ogg` loudest here — a car that never arrives.
- Stealth: cars give hard cover in a line; this is the hunter's approach lane.

### z_scavenger_camp — the camp behind the outbuilding (o cell)
- Props: burn drum (unlit in DARK/PARTIAL, lit prop from STREETS), tarp lean-tos, bed rolls,
  rules board on the post (`props/examine.tscn` → `gas_station_note_08`, FULL only),
  `camp_crate` containers ×2, hooded lamp on a wire.
- Pickups: fixed `gas_station_fix_camp_01` (2× fabric); rolls non-empty by R6.
- Stage behavior: the camp is the one place that gets *warmer* rather than brighter —
  the drum fire is the warm point, the hooded lamp stays hooded even at FULL (camp rule 2).

### z_generator_yard — generator pad behind the shop (GG cell)
- Props: `props/puzzle_3d.tscn` pad wired to `PowerSwitch` (this is `fuse_gas_station`),
  `surfaces/generator_metal_512.png` genset, `surfaces/fusebox_512.png` panel, cable drums,
  `tool_cage`, chain-link fence with a cut flap (the way the crew got in).
- Pickups: fixed `gas_station_fix_puzzle_01` (2× cable); 1 rolled `tool_cage`.
- Ambience: `substation_cable_hum.ogg` at −12 dB once powered (existing file reused).

### z_exit_east — east exit toward the police road (C cell)
- Props: barrier, road sign "Полиция →", last usable streetlight, `wash_bay_bin`.
- Pickups: 1 rolled `wash_bay_bin`. No fixed cache (the defense cache is one zone back on
  the slip road, R7 keeps flame away from the pumps).

## Streetlight & stage-state summary

| Stage | Lights lit (of 5 usable) | Warm points | Ambience shift |
|-------|--------------------------|-------------|----------------|
| DARK (0)    | 0 + canopy flicker  | none (flashlight only)      | gas_station_dark bed + sign buzz + gravel + distant car pass |
| PARTIAL (1) | 2 (canopy pair)     | shop fridge glow (dead cold)| pump hum rises slightly |
| STREETS (2) | 4 (+ apron, slip road) | drum fire in camp        | sign buzz steadies (the buzz was the fault, not the sign) |
| FULL (3)    | 5 + price totem     | drum fire + totem digits    | warm lit layer — `gas_station_lit.ogg`, spec in docs/AUDIO_COVERAGE.md |

## Art / audio gaps

1. Lit tile twins `tiles/gas_station_floor_lit.png` / `gas_station_wall_lit.png` —
   **filled by this pass** (generated, §4.1 numeric test recorded in `docs/ASSET_LICENSES.md`).
2. Fuel-pump prop surface `surfaces/fuel_pump_512.png` — **filled by this pass**.
3. Canopy / price-totem / burn-drum props — placeholder boxes until art lands (no blocking
   dependency; existing debris and drum props cover the zones meanwhile).
4. Audio `districts/gas_station_lit.ogg` — **real gap**, full spec in
   `docs/AUDIO_COVERAGE.md` (not fabricated here). Dark bed and all 4 detail one-shots
   exist and were header-verified this pass.
