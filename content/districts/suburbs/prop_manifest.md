# Prop Manifest — District `suburbs` (template district)

Owner: CONTENT (this file is a placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §14 (perf: draw calls <200 D1, <50K polys/district).
Scene to wire: `scenes/districts/suburbs.tscn` (existing nodes: `StreetBuilder`, `Props`,
`PowerSwitch`, `EmissiveWindows`, `DistrictTrigger`). Legacy spawn data: `data/districts.json` —
suburbs weather `fog`, enemies `watcher`, `shadow`.

Zones below are the content-side map; same ids are used by `item_spawns.json` (`zones` array)
and `lore_notes.json` (`location_hint`), so one wiring pass covers all three files.

## Zone map (8 zones)

```
        z_exit_north (to residential)
             |
   z_backyards | z_cul_de_sac
  -------------+-------------  <- z_maple_row (main street, W->E)
   z_garage_row   z_bus_stop
             |
        z_corner_shop
             |
        z_spawn_edge (district entry, S)
```

## Per-zone plan

### z_spawn_edge — entry, SAFE-ish
- Props: 1 flickering `props/streetlight_3d.tscn` at the gate (already-lit beacon teaching the goal —
  GDD §3: "войти в тёмный район → вернуть свет"). 2 wrecked cars (existing environment props), debris piles.
- Pickups: none rolled here (safe-start rule R1 in item_spawns).
- Examine: district entry sign (cosmetic, no note).
- Stage behavior: DARK = flicker only; STREETS+ = steady light. `EmissiveWindows`: 2 windows on at PARTIAL.

### z_maple_row — main street (blue two-story house = note anchor)
- Props: 4 streetlights (`props/streetlight_3d.tscn`) spaced 1 per ~10 tiles, all DARK at stage 0.
  Power line fragments between poles (existing environment debris) — visual promise of the puzzle.
- Pickups: house kitchen drawers (2 containers `kitchen_drawer`; fixed spawn `suburbs_fix_puzzle_03` here).
- Examine: `props/examine.tscn` → photo `suburbs_note_01` on the porch of the blue house.
- Ambience: `suburbs_porch_creak.ogg` proximity loop at porches (DARK only), `suburbs_wind_leaves.ogg` base layer.

### z_bus_stop — kiosk + community board
- Props: bus stop shell, bench, leaning lamppost (broken — never lights; environmental storytelling).
- Pickups: 1 `trash_bin` container; fixed `suburbs_fix_defense_01` (2× molotov, STREETS+).
- Examine: `props/examine.tscn` → `suburbs_note_02` (maintenance notice on the board).
- Ambience: distant `suburbs_dog_bark.ogg` one-shots on a 40–90 s random timer (DARK only).

### z_corner_shop — supplies hub (has a locked back room)
- Props: shop interior shelving (3 `shop_shelf` containers), counter, boarded back-room door
  (locked by `suburbs_fix_key_01` — code agent wires lock).
- Pickups: rolled loot ×3; fixed `suburbs_fix_teach_01` (makeshift_lamp on a shelf, visible through window).
- Examine: `props/examine.tscn` → `suburbs_note_03` (evacuation leaflet in the mail slot).
- Stage behavior: at FULL, `EmissiveWindows` lights the shopfront — safest room at night.

### z_garage_row — puzzle-material anchor + grid crew story
- Props: 3 open garages, 1 car on jacks, work bench, cable spools (environment prop).
- Pickups: 2 `garage_shelf` + 1 `car_trunk` containers; fixed spawns
  `suburbs_fix_puzzle_01` (2× fuse), `suburbs_fix_puzzle_02` (3× cable), `suburbs_fix_upgrade_01` (backpack_l1, PARTIAL+).
- Examine: `props/examine.tscn` → audio_log `suburbs_note_04` on the work bench.
- Notes: this zone is the "why" of the district — the grid crew that proved one streetlight can burn.

### z_cul_de_sac — highest-risk pocket, best loot door
- Props: 3 houses, boarded windows, overturned trash cans (cover for stealth vs `watcher`/`shadow`).
- Pickups: 2 `kitchen_drawer` containers; fixed `suburbs_fix_key_01` (key → corner shop back room).
- Examine: 2× `props/examine.tscn` → `suburbs_note_05` (doorstep note), `suburbs_note_08` (watch roster, kitchen table).
- Ambience: dog bark one-shots originate here after `suburbs_note_08` is read ( optional flavor; code decides).

### z_backyards — connective tissue, quiet
- Props: fences, clotheslines, garden clutter, 1 yard swing.
- Pickups: 1 `trash_bin`, 1 `mail_box` container.
- Examine: `props/examine.tscn` → photo `suburbs_note_06` (child's drawing, on the swing; PARTIAL+).

### z_exit_north — exit to `residential` + emotional close
- Props: the LAST LIT streetlight (the one from grid crew logs) — always lit, never part of the puzzle;
  barricade with a passage, road sign "Район 2 →".
- Pickups: fixed `suburbs_fix_exit_01` (3× battery in `mail_box`).
- Examine: `props/examine.tscn` → audio_log `suburbs_note_07` under the lit streetlight (STREETS+).
- Purpose: the district ends on the canon line "фонари ещё горят" — light visible from `z_maple_row` pulls the player north.

## Stage-state summary (wire into `PowerSwitch` / `PowerGrid`)

| Stage | Streetlights lit (of 5 usable) | EmissiveWindows | Ambience shift |
|-------|-------------------------------|-----------------|----------------|
| DARK (0)   | 0 + flicker at spawn | 0 | dark loop + porch creak + dog barks |
| PARTIAL (1)| 2 (z_maple_row W half) | 2 windows | crossfade toward lit loop |
| STREETS (2)| 4 | shopfront + 3 | lit loop, dog barks off |
| FULL (3)   | 5 + exit beacon bright | all mapped | warm lit loop (GDD §4.2 "LIT звучит теплее") |

## Content gaps (art/audio — prompts go to `docs/ART_PROMPTS.md`, code never blocks)

1. Suburb house facade variant with porch (facade set reuse ok) — `z_maple_row`/`z_cul_de_sac`.
2. Broken leaning lamppost variant (non-functional) — `z_bus_stop`.
3. Cable spool + jack car garage clutter set — `z_garage_row`.
4. Audio: 1 short "power returns" riser for streetlight re-light moment (global, reusable per district).
