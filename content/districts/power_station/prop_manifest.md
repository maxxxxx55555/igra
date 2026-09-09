# Prop Manifest — District `power_station` (district 11, CHAIN TERMINAL / FINALE)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §4.3 (prereq at FULL:
`power_station.powered_by = [&"substation"]`),
§12.3 (**Act III finale**: D11 — the last district; there is no road past it), §14 perf.
`radio_03_keeper_reversal` is gated on **power_station itself** at min_stage 1 — this is
the first and only district where it may spawn (power_station_note_03, carried at the gate
exactly so the finale front-loads the Keeper's answer). LORE ONLY: this pack resolves
people and paper and never touches GDD §12.4 content or code mechanics (CODE's zone).
Scene to wire: `scenes/districts/power_station.tscn` (already scaffolded with the sibling
node contract: `StreetBuilder`, `PowerSwitch`, `DistrictTrigger`, `EmissiveWindows`,
`Props`). Opens at **substation FULL** (GDD §4.3). Powers nothing — the terminal.
Enemies (canon, `enemy_pool.gd`): `destroyer`, `destroyer`, `watcher` — **double
destroyer, the heaviest lead in the chain**: no light reaction at all, and both *break
nearby streetlights while patrolling* (`destroyer_3d.gd`). Light here is less than a
consumable — it is bait; the cues are the twin machinery hums (audible 12 m), the weakness
the 5 m / 180° cones — cover is generator-block spacing. Watcher: the ops/archive
corridor; 2 s beam-stun then rage ×1.25 / 5 s; breath at 5 m; the 15 m scream pulls BOTH
destroyers at once.
Theme (`district_themes.gd`): primary `#5a5a5a` (concrete grey), accent `#f4f45d`
(signal yellow — STYLE_GUIDE §2: hotter than the ember token; keep it to small emissives
only, never on surfaces, same handling as substation/industrial), sky `#0c0c0c`,
fog `_FOG_CANON`, ambient `#161616`, weather **fog**. Music (`music_manager.gd`):
`music_ambient_dark.wav` (the `district_themes.gd` row is colour-only, no `"music"` key —
same class as every district since police, no mismatch to flag).
Puzzle canon: `puzzle_system.gd` `reactor_power_station` → the pad in `z_reactor_room`
(GG cell). This pack cites the puzzle id and its zone only — the reward and mechanics are
CODE's zone and are never stated here (R4).
Themed loot canon (`district_loot.gd` BY_DISTRICT): fuse, transistor, medkit — the finale
pays out chain parts plus mercy (medicine).
Story doc canon: `doc_core_station` (800 MW passport, DO NOT START AFTER 23:00, the pencil
line "generators no longer produce current — they produce voices") — extended, never
copied, by `power_station_note_04` (the pencil line's author).

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference the `DistrictLayouts` power_station grid
advisory-style: `GG` reactor room, `K`/`L` operations, `T` crew camp, `m` cooling yard,
`c` archive, `f` turbine hall, `o` signal loft, `D` station gate entry (from the
substation east road), `B` bunker (the Keeper's racks — geography, the layout's own cell).

## Zone map (10 zones)

```
        [west block]                         [east block]
 z_reactor_room (GG, the          z_turbine_hall (f, Hall 1,
   reactor pad)                     three generators)
 z_operations (K/L, duty         z_cooling_yard (m, between
   board + archive key)              the blocks)
 z_crew_camp (T, the crew's      z_archive (c, locked records,
   center camp)                      never lit)
 z_station_gate (D, entry +       z_signal_loft (o, the big
   the last road's end)              receiver)
                                      z_bunker (B, the racks, never lit)
                                      z_cooling_towers (exterior stacks)
```

Two blocks face each other across the cooling yard. The west block holds the gate, the
crew's last camp, operations and the reactor room; the east block holds the hall, the
archive and the signal loft; the bunker and the towers close the district — past them
there is no road, only the fence and the fog.

## Per-zone plan

### z_station_gate — entry from the substation road, SAFE-ish (D cell)
- Props: station gate with the crew's hand truck inside it (chalk manifest,
  `props/examine.tscn` → `power_station_note_01`), barrier arm, road sign
  "Электростанция — центральная" facing the substation road, chain-link, one lamp on the
  gate pier, `cargo_crate` ×3, fog off the yard.
- Pickups: fixed `power_station_fix_exit_01` (3× battery),
  `power_station_fix_defense_01` (2× noise_bomb, STREETS+, the air-horn test canisters),
  `power_station_fix_med_02` (2× medkit, FULL only, the mercy cache); no rolled loot
  (safe-start rule).
- Stage behavior: DARK = gate lamp dead; STREETS+ the pier lamp takes a low warm
  `#c9a24a` throw; FULL = the bowl at its foot (prop — Manya's rule kept at the center,
  note_08). The barrier stays down until the district opens (trigger).
- Ambience: `power_station_breaker_clunk.ogg` (3.0 dB) faintest here — the hall's voice
  at a distance.

### z_turbine_hall — Hall 1, three generators (f cell)
- Props: three generator blocks (the middle one churns the dark above it — the
  `power_station_note_02` subject, prop only), gallery rail with the photo wedged in it
  (`props/examine.tscn` → `power_station_note_02`), oil trenches, `parts_bin` ×1,
  hall lamp pair (usable `props/streetlight_3d.tscn` ×2).
- Pickups: fixed `power_station_fix_hall_01` (1× transformer, the hall bin — optional
  risk-reward inside destroyer A's patrol); 2 rolled `parts_bin`.
- Stealth: DESTROYER A COUNTRY — it walks the generator row and breaks the hall lamps it
  passes; 5 m / 180° sight means the generator blocks are the cover, the hum at 12 m is
  the warning. No chain component, key or note lives only here (R1/R5).
- Ambience: `power_station_generator_thrum.ogg` (0.0) strongest here — the hall's own
  voice; `power_station_hv_whine.ogg` (0.0) bleeding from the busbars.

### z_reactor_room — the reactor pad (GG cell)
- Props: `props/puzzle_3d.tscn` pad wired to `PowerSwitch` (this is
  `reactor_power_station` — cited by id and zone only, R4), feeder map on the wall, spool
  rack with drum cable, `cable_spool` ×1, one ceiling lamp (usable ×1).
- Pickups: fixed `power_station_fix_puzzle_01` (2× cable, the spool);
  1 rolled `cable_spool`.
- Stage behavior: DARK = dead; PARTIAL = the room takes its first pilot lights (the
  district's own circuit); FULL = steady.
- Fire discipline: no molotov/noise_bomb cache here (R8).
- Ambience: `power_station_hv_whine.ogg` (0.0) closest here; the pad itself is silent.

### z_operations — duty board + archive key (K/L cells)
- Props: duty board with the passport file on the desk (`props/examine.tscn` →
  `power_station_note_04`, PARTIAL+), night engineer's desk with the archive key in the
  unlocked drawer, fuse cabinet under the board, `fuse_cabinet` ×1, `office_desk` ×1
  rolled, window looking out over the hall and the towers.
- Pickups: fixed `power_station_fix_key_01` (archive key, unlocked drawer),
  `power_station_fix_puzzle_02` (2× fuse, the cabinet); 1 rolled `office_desk`.
- Purpose: the key-chain start; reachable in DARK so R1 holds. The window is the one clean
  sightline over destroyer A's hall — use it to read the patrol, not to fight it.
- Stage behavior: operations lamp usable from PARTIAL (the board is read by window spill
  before that).

### z_cooling_yard — between the blocks (m cell)
- Props: cooling-fan housings, fan cowls, frost gravel, warning placards, one yard lamp
  (usable ×1), `oil_drum` ×1 rolled.
- Pickups: fixed `power_station_fix_yard_01` (3× scrap, the frost drum — optional
  risk-reward inside destroyer B's patrol); 1 rolled `oil_drum`.
- Stealth: DESTROYER B COUNTRY — it walks the fan row; the cowls are the cover, the hum
  at 12 m is the warning. Cross at the gravel, never along the row (R5).
- Ambience: `power_station_cooling_fan.ogg` (0.0) — the yard sings the hall's song up
  close.

### z_archive — locked records (c cell, **never relit — R8**)
- Props: record shelving, the memorandum file with the last memorandum on top
  (`props/examine.tscn` → `power_station_note_05`, STREETS+), solid-state spare rack,
  viewing slit in the door, cable runs entering from the reactor room.
- Pickups: fixed `power_station_fix_puzzle_03` (2× transistor); 1 rolled `relay_rack`
  (rich, ×1.3 — the archive's solid-state is the district's one fat cache).
- Lock: `power_station_fix_key_01` from the operations desk. Short corridor, single door —
  the DARK solvability room (R1). Never lit (R8); read by corridor spill, mirrors
  substation's vault.
- Stealth: the watcher holds this corridor; the slit lets you confirm the room before you
  commit to the lock — and the scream pulls both destroyers, so commit only when the hums
  are far (R5).

### z_crew_camp — the crew's center camp (T cell)
- Props: camp beds, the names cassette in the player (`props/examine.tscn` →
  `power_station_note_07`, STREETS+), first-aid locker, cached drums, the crew's route
  chalked on the wall (the whole line, suburbs to here, and the line stops — there is no
  arrow past the station), `steel_locker` ×1, one camp lamp (usable ×1).
- Pickups: fixed `power_station_fix_med_01` (2× medkit, the crew's stocked locker);
  1 rolled `steel_locker`.
- Stage behavior: the camp lamp takes a low warm throw at PARTIAL — the crew's camp lit
  for whoever walks the line last.
- Ambience: quietest zone; the hall's generator thrum arrives here −12 dB through the
  wall — a thrum that is not quite a thrum.

### z_signal_loft — the big receiver (o cell)
- Props: the station's big receiver with the answer tape in it (`props/examine.tscn` →
  `power_station_note_03`, PARTIAL+), antenna feedlines, operator's chair, logbook of
  received broadcasts (prop — the call logged for a year, then the answer), one loft lamp
  (usable ×1).
- Pickups: 1 rolled `parts_bin` (receiver spares).
- Stage behavior: the loft lamp takes a low warm throw at PARTIAL — the answer is read in
  lamplight, the way broadcasts deserve.
- Ambience: `power_station_breaker_clunk.ogg` (3.0) through the floor; the receiver itself
  is silent until played.

### z_bunker — the Keeper's racks (B cell, **never relit — R8**)
- Props: floor-to-ceiling lamp racks (cleaned housings, brass racked apart from iron,
  wire tags naming streets), the tally board (prop, count stops at 219 + rows by design),
  the bunker photograph taped to the rack end (`props/examine.tscn` →
  `power_station_note_06`, STREETS+), no lamp — the room is read by hand-lamp spill only.
- Pickups: none, fixed or rolled — the bunker is a reliquary, not a store (R8).
- Stage behavior: never lit at any stage. The racks are examined by hand-lamp; nothing in
  the room burns.
- Ambience: dead air; the hall's thrum arrives −18 dB through earth and concrete.

### z_cooling_towers — the exterior stacks (outside the blocks)
- Props: cooling-tower shells, the gantry with the photograph pinned to its rail
  (`props/examine.tscn` → `power_station_note_08`, FULL only), the gate lamp visible below
  (the photo's subject — the lamp itself lives in `z_station_gate`), poplar row leaning
  gateward (prop — the groundskeeper's note, note_08), fence and fog past it.
- Pickups: 1 rolled `cargo_crate` (road staging). No fixed cache — the towers are a
  threshold, not a store.
- Stage behavior: at FULL the towers take floodlight from below (the district's last warm
  points besides the gate lamp); the gantry photo reads by that light.
- Stealth: destroyer B walks the towers edge; the shells are the cover. The photo is
  reachable without crossing the patrol line (R1/R5).
- Ambience: `power_station_cooling_fan.ogg` (0.0) thinnest here; wind through the shells.

## Streetlight & stage-state summary

| Stage | Lights lit (of 11 usable) | Warm points | Ambience shift |
|-------|---------------------------|-------------|----------------|
| DARK (0)    | 0 (the hall is a silhouette; both destroyers break what burns) | none; fog holds the hall | power_station_dark bed + generator thrum + hv whine + cooling fan + breaker clunk |
| PARTIAL (1) | 3 (station gate, reactor room, crew camp) | the crew's camp first — the camp lamp for whoever walks last | thrum steadies; whine stays (the middle machine still churns) |
| STREETS (2) | 7 (+ hall lamp A, operations, cooling yard, signal loft) | the hall readable from the operations window | whine −6; fan warms; clunk stays |
| FULL (3)    | 11 (all: + hall lamp B, gate pier flood, towers floods, yard north) | the gate lamp + the lit towers + the silent bunker door | warm lit layer — `power_station_lit.ogg` (ships; header-verified by this PR, see AUDIO_COVERAGE) |

`z_archive` and `z_bunker` stay unlit at every stage (R8). Both destroyers will break
relit lamps on their patrols — that is intended (R5): the stage table is the ceiling, not
a floor; CODE should treat lamp breakage as gameplay, not a bug to guard against.

## Art / audio gaps

1. Lit tile twins — **no gap**: `tiles/power_station_floor_lit.png` /
   `tiles/power_station_wall_lit.png` already ship (pre-existing; re-measured by this
   PR's asset pass for the record, see `docs/ASSET_LICENSES.md`).
2. Power-station prop faces — spec only, non-blocking (placeholder boxes / existing
   surfaces cover the zones meanwhile, mirroring the substation pass):
   - `surfaces/archive_shelf_512.png` — record-shelving face for the archive walls
     (paper spines over panel `#141b24`, signal-yellow `#f4f45d` file tags as the only
     accent, kept small; matte, unlit, no readable text).
   - Optional: the bunker-rack visual (low rack mesh reusing
     `surfaces/metal_rust_512.png`; the tags are CODE/UI, never baked into art).
3. Audio — **no gap**: `districts/power_station_dark.ogg` and
   `districts/power_station_lit.ogg` both ship, plus all 4 detail one-shots; header-
   verified by this PR (see `docs/AUDIO_COVERAGE.md`). No spec appended.
