# Prop Manifest — District `industrial` (district 9)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §4.3 (prereqs at FULL — **both** parents here:
`industrial.powered_by = [&"warehouses", &"police"]`, the chain's first two-parent convergence),
§9 (D9 "Батарея L2" workbench *location* — no new blueprint id; industrial is not one of the
four BLUEPRINTS districts per `district_loot.gd`), §12.3 (**Act III begins**: D9–11 — but the
Act III broadcasts `radio_02`/`radio_03` are gated on substation/power_station, which are NOT
in industrial's closure, so no Act III id may spawn here; the act boundary moves the story,
not the gates), §14 perf.
Scene to wire: `scenes/districts/industrial.tscn` (already scaffolded with the sibling node
contract: `StreetBuilder`, `PowerSwitch`, `DistrictTrigger`, `EmissiveWindows`, `Props`).
Opens at **warehouses FULL + police FULL** (both required, GDD §4.3). Powers `substation`
— not a leaf.
Enemies (canon, `enemy_pool.gd`): `destroyer`, `hunter`, `watcher` — **destroyer leads, and
it is the harshest lead in the chain**: no light reaction at all, and it *breaks nearby
streetlights while patrolling* (`destroyer_3d.gd` `_try_break_nearby_lights`). Light here is
a spent consumable, never a tool; the destroyer's cue is its machinery hum (audible 12 m) and
its weakness is the 5 m / 180° cone — cover is machine-footprint spacing. Hunter: beam slows
×0.5, then rage ×1.3 for 5 s the moment the light leaves. Watcher: 2 s beam-stun then rage
×1.25 / 5 s; breath at 5 m; the 15 m scream pulls the floor.
Theme (`district_themes.gd`): primary `#5a4a3a` (umber), accent `#e85d3a` (ember-hot —
STYLE_GUIDE §2: hotter than the ember token; keep it to small emissives only, never on
surfaces, same handling as warehouses/police), sky `#100d0a`, fog `_FOG_CANON`, ambient
`#1a140f`, weather **fog**. Music (`music_manager.gd`): `industrial.wav` (the
`district_themes.gd` row is colour-only, no `"music"` key — same class as police/warehouses,
no mismatch to flag).
Puzzle canon: `puzzle_system.gd` `generator_industrial` (reward **2× medkit**, `power_stage` 2).
Themed loot canon (`district_loot.gd` BY_DISTRICT): fuse, transistor, gear, metal — the plant
that machined the city's grid hardware is its own parts bin.
Story doc canon: `doc_factory_log` (Factory #9 shift log: 22:00 hum from the generator,
23:15 flicker in workshop B) — extended, never copied, by `industrial_note_02` (the 23:15
photograph) and `_01`/`_03`.

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference the `DistrictLayouts` industrial grid
advisory-style: `GG` generator hall, `K`/`L` foreman catwalk office, `T` locker room,
`s` stores yard, `c` switchgear room, `f` factory floor, `o` workshop B, `b` assembly
line, `D` dock entry (from the warehouses east-gate road), `H` south gate (the road to
the substation — the D10 threshold of no return lies beyond it).

## Zone map (10 zones)

```
        [west hall]                          [east hall]
 z_generator_hall (GG)      z_factory_floor  z_stores_yard (s, yard bins)
 z_foreman_catwalk (K/L,    (f, between the  z_workshop_b (o, the 23:15 room)
   mezzanine over GG)        two halls)      z_switchgear_room (c, locked, never lit)
 z_locker_room (T)                            z_assembly_line (b, south run + grease pit)
 z_loading_dock (D, entry)                    z_south_gate (H, road to the substation)
```

Two halls face each other across the open factory floor, joined at the south by the assembly
line's run. The west hall holds the feeder plant under the foreman's catwalk; the east hall
holds the stores, Workshop B and the switchgear room; the line's tail disappears into the
grease pit at the south end — the district's one uncanny through-line (notes 02/03/07).

## Per-zone plan

### z_loading_dock — entry from the warehouses east-gate road, SAFE-ish (D cell)
- Props: dock office with the time-card rack (`props/examine.tscn` → `industrial_note_01`),
  barrier arm, road sign "Завод №9 →" facing the warehouses road, chain-link, one lamp on the
  office wall, `cargo_crate` ×2, fog off the yard.
- Pickups: fixed `industrial_fix_exit_01` (3× battery), `industrial_fix_defense_01`
  (2× noise_bomb, STREETS+, the air-horn test canisters); no rolled loot (safe-start rule).
- Stage behavior: DARK = office lamp dead; STREETS+ the office wall lamp takes a low warm
  `#c9a24a` throw; the barrier stays down until the district opens (trigger).
- Ambience: `industrial_vent_rattle.ogg` (4.5 dB) loudest here — the dock vents.

### z_factory_floor — the open floor between the halls (f cell)
- Props: machine footprints (press bases, lathe beds — all dead, mid-stroke frozen), the
  peening press with the photo taped to its guard (`props/examine.tscn` →
  `industrial_note_02`), coolant trenches, pallet staging, high-bay lamp pair (usable
  `props/streetlight_3d.tscn` ×2).
- Pickups: 2 rolled `cargo_crate`.
- Stealth: DESTROYER COUNTRY — it patrols the floor's length and breaks the high-bays it
  passes; 5 m / 180° sight means the trench edges and press bodies are the cover, the hum at
  12 m is the warning. No chain component, key or note lives only here (R1/R5).
- Ambience: `industrial_machinery_drone.ogg` (4.0 dB) — the floor's dead hum, strongest
  here; `industrial_steam_vent.ogg` (0.0) as isolated one-shots from the trenches.

### z_assembly_line — the line, south run + grease pit (b cell, south end never lit)
- Props: the sorting conveyor running to the grease pit, the pallet of brass lamp shells
  with no order number (`industrial_note_03`'s pallet — prop, not container), drum stock
  along the pit, one high-bay at the north end only (usable ×1), `oil_drum` ×1 rolled.
- Pickups: fixed `industrial_fix_line_01` (3× scrap, the pit — optional risk-reward inside
  the destroyer's second patrol room).
- Stage behavior: the line NEVER runs audibly and never lights at any stage (R8) — it is the
  anomaly, not wallpaper; at STREETS+ the north high-bay lets you *see* it sorting, which is
  worse. The pit stays dark at every stage.
- Ambience: nothing from the line — dead air plus `industrial_machinery_drone.ogg` (4.0)
  bleeding from the floor. The line must never become a sound cue.

### z_generator_hall — feeder plant under the catwalk, west hall (GG cell)
- Props: `props/puzzle_3d.tscn` pad wired to `PowerSwitch` (this is `generator_industrial`),
  the district feeder map on the wall, the shift log's generator (doc_factory_log's 22:00
  hum — a prop silhouette, never an audio source), `tool_chest` ×1, cable runs to the
  switchgear wall.
- Pickups: fixed `industrial_fix_puzzle_01` (2× cable); 1 rolled `tool_chest`.
- Stage behavior: DARK = dead; PARTIAL = the generator takes its first warm glimmer (the
  district's own circuit); FULL = hum steady and warm.
- Ambience: `substation_cable_hum.ogg` at −12 dB once powered (existing file reused, no new
  audio); `industrial_pipe_hiss.ogg` (0.0) faint from the runs.

### z_foreman_catwalk — mezzanine office + catwalk over the west hall (K/L cells)
- Props: catwalk rail over the generator hall, office desk with the works ledger
  (`props/examine.tscn` → `industrial_note_04`), wall clock stopped at 23:15, `office_desk`
  ×1 rolled, window looking out over the factory floor and the south gate.
- Pickups: fixed `industrial_fix_key_01` (switchgear key, unlocked top drawer); 1 rolled
  `office_desk`.
- Purpose: the key-chain start; reachable in DARK so R1 holds. The catwalk is the one clean
  sightline over the destroyer's floor — use it to read the patrol, not to fight it.
- Stage behavior: office lamp usable from FULL only (the desk is read by window spill before
  that).

### z_stores_yard — open stores and cage, east hall north (s cell)
- Props: yard-parts bins, the stores cage with the works-order file (`props/examine.tscn` →
  `industrial_note_05`, STREETS+), two yard floods on poles (usable ×2), `scrap_bin` ×2,
  `parts_bin` ×2, billet-stock pallets.
- Pickups: fixed `industrial_fix_puzzle_02` (2× fuse, parts bin),
  `industrial_fix_stores_01` (2× metal, scrap bin); 2 rolled `parts_bin` + 1 rolled
  `scrap_bin`.
- Stealth: HUNTER territory — the yard's long rows are charge lanes (charge 8.0 m/s after a
  1.0 s roar windup); never strobe-and-run here, the beam's exit is the trigger (R5).
- Ambience: `industrial_steam_vent.ogg` (0.0) from the yard risers; `industrial_vent_rattle.ogg`
  (4.5) from the cage wall.

### z_workshop_b — the 23:15 room, east hall (o cell)
- Props: the bench under the impossible lamp (a dead overhead that burned at 23:15 with no
  feeder — note_02's subject), the Workshop B conveyor tail sorting brass lamp shells,
  `toolbox` ×1, `props/examine.tscn` → `industrial_note_03` (the recorder on the bench,
  PARTIAL+), solvent-degreaser drums.
- Pickups: fixed `industrial_fix_stores_02` (2× gear); 1 rolled `toolbox`.
- Stage behavior: the bench lamp takes a low warm throw at PARTIAL (it was the first thing
  in the plant to come back — the plant's own joke on the shift log).
- Fire discipline: no molotov/noise_bomb cache here (solvent drums — R8).
- Ambience: `industrial_pipe_hiss.ogg` (0.0) closest here; the conveyor is silent.

### z_switchgear_room — locked solid-state room, east hall shared wall (c cell, **never relit — R8**)
- Props: mesh-caged switchgear cabinets, the winding refusal clipped inside the cabinet door
  (`props/examine.tscn` → `industrial_note_06`, STREETS+), viewing slit in the door, cable
  runs entering from the generator hall.
- Pickups: fixed `industrial_fix_puzzle_03` (2× transistor); 1 rolled `switchgear_cabinet`
  (rich, ×1.5 — the plant's solid-state is the district's one fat cache).
- Lock: `industrial_fix_key_01` from the foreman's desk. Short corridor, single door —
  the DARK solvability room (R1). Never lit (R8); read by corridor spill, mirrors
  warehouses' quarantine cage.
- Stealth: watchers drift the corridor; the slit lets you confirm the room before you
  commit to the lock.

### z_locker_room — shift lockers, west hall south (T cell)
- Props: steel lockers, bench, the roll-call cassette in the player
  (`props/examine.tscn` → `industrial_note_07`, STREETS+), punched time cards fanned on the
  bench, `steel_locker` ×1 rolled + the first-aid locker.
- Pickups: fixed `industrial_fix_med_01` (2× medkit); 1 rolled `steel_locker`.
- Ambience: quietest zone; the floor's machinery drone arrives here −12 dB through the wall
  — press-stroke spaced, a rhythm that is not quite a rhythm.

### z_south_gate — the gate and the substation road (H cell)
- Props: the south gate, works fence, the road running south, the gate lamp (usable ×1),
  the catwalk-shot photo taped to the gate (`props/examine.tscn` → `industrial_note_08`,
  FULL only), milestone post "Подстанция — 4".
- Pickups: 1 rolled `cargo_crate` (road staging). No fixed cache — the gate is a threshold,
  not a store.
- Stage behavior: the gate lamp takes FULL's warm throw and the gate stands open — past it
  is D10, the point of no return (GDD §12.3). Nothing here ever says so out loud; the photo
  does (note_08).
- Ambience: `industrial_vent_rattle.ogg` (4.5) fading south into open fog.

## Streetlight & stage-state summary

| Stage | Lights lit (of 11 usable) | Warm points | Ambience shift |
|-------|---------------------------|-------------|----------------|
| DARK (0)    | 0 (the plant is a silhouette; the destroyer breaks what burns) | none; fog holds the floor | industrial_dark bed + machinery drone + vent rattle + pipe hiss |
| PARTIAL (1) | 3 (dock office, generator hall, Workshop B bench) | the bench lamp first — the 23:15 joke | drone steadies; steam vents thin |
| STREETS (2) | 7 (+ factory-floor pair, yard flood A, south gate) | the line visible sorting at the north high-bay | pipe hiss −6; rattle stays |
| FULL (3)    | 11 (all: + yard flood B, catwalk office, locker room, line north bay) | office window + the open south gate | warm lit layer — `industrial_lit.ogg`, spec in docs/AUDIO_COVERAGE.md |

`z_switchgear_room` stays unlit at every stage, and the assembly line's south run / grease
pit never lights (R8). The destroyer will break relit high-bays on its floor patrol — that
is intended (R5): the stage table is the ceiling, not a floor; CODE should treat lamp
breakage as gameplay, not a bug to guard against.

## Art / audio gaps

1. Lit tile twins `tiles/industrial_floor_lit.png` / `industrial_wall_lit.png` —
   **filled by this pass** (derived from the shipped dark twins, which were seam-probed
   clean first: 3.81 / 3.08, no edge-frame defect; §4.1 numbers in
   `docs/ASSET_LICENSES.md`).
2. Industrial prop faces — spec only, non-blocking (placeholder boxes / existing surfaces
   cover the zones meanwhile, mirroring the warehouses pass):
   - `surfaces/switchgear_512.png` — caged cabinet face for the solid-state room (steel
     mesh over panel `#141b24`, brass `#c9a24a` breaker tips as the only accent; matte,
     unlit, no text).
   - Optional: the sorting-line visual (low conveyor mesh reusing
     `surfaces/metal_rust_512.png`; no motion at any stage — a corpse of a machine, same
     rule as the warehouses sorter).
3. Audio `districts/industrial_lit.ogg` — **real gap**, full spec in
   `docs/AUDIO_COVERAGE.md` G2h (not fabricated here). Dark bed and all 4 detail one-shots
   exist and were header-verified this pass (bed 1 ch/44.1 kHz/33.994 s — the only
   district bed off the 36.000 s house contract, both readings recorded in G2h; one-shots
   1 ch/44.1 kHz/30.000 s).
