# Prop Manifest — District `substation` (district 10)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §4.3 (prereq at FULL:
`substation.powered_by = [&"industrial"]`),
§12.3 (**Act III**: D9–11 — **the point of no return is entering D10**; the gatehouse
marks the threshold in prose, never in UI), §14 perf. `radio_02_grid_crew_relay` is gated
on **substation itself** at min_stage 1 — this is the first district where it may spawn
(substation_note_07, paced at STREETS for district rhythm); `radio_03_keeper_reversal`
stays gated on power_station and must never spawn here.
Scene to wire: `scenes/districts/substation.tscn` (already scaffolded with the sibling node
contract: `StreetBuilder`, `PowerSwitch`, `DistrictTrigger`, `EmissiveWindows`, `Props`).
Opens at **industrial FULL** (GDD §4.3). Powers `power_station` — not a leaf.
Enemies (canon, `enemy_pool.gd`): `destroyer`, `watcher`, `hunter` — **destroyer leads for
the second district running**: no light reaction at all, and it *breaks nearby streetlights
while patrolling* (`destroyer_3d.gd`). Light stays a spent consumable, never a tool; the
cue is the machinery hum (audible 12 m), the weakness the 5 m / 180° cone — cover is
transformer-tank spacing. Watcher: the relay/control corridor; 2 s beam-stun then rage
×1.25 / 5 s; breath at 5 m; the 15 m scream pulls the yard. Hunter: the cable trench;
beam slows ×0.5, then rage ×1.3 for 5 s the moment the light leaves.
Theme (`district_themes.gd`): primary `#5a5a5a` (concrete grey), accent `#f4f45d`
(signal yellow — STYLE_GUIDE §2: hotter than the ember token; keep it to small emissives
only, never on surfaces, same handling as industrial's ember-hot accent), sky `#0c0c0c`,
fog `_FOG_CANON`, ambient `#161616`, weather **fog**. Music (`music_manager.gd`):
`music_ambient_dark.wav` (the `district_themes.gd` row is colour-only, no `"music"` key —
same class as industrial/police/warehouses, no mismatch to flag).
Puzzle canon: `puzzle_system.gd` `fuse_substation` (reward **coins 200**, `power_stage` 2).
Themed loot canon (`district_loot.gd` BY_DISTRICT): fuse, cable, transistor — the repair
chain itself is the theme; the building that routes the city's power pays out in parts.
Story doc canon: `doc_substation_guard` (the welded door that opened by itself at 03:00,
darkness on the threshold, logged as a sensor trip) — extended, never copied, by
`substation_note_01` (the guard's duplicate logbook).

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference the `DistrictLayouts` substation grid
advisory-style: `GG` relay room, `K`/`L` control room, `T` crew bunk, `m` cable trench,
`c` switchgear vault, `f` transformer yard, `o` arc-flash cage, `D` gatehouse entry
(from the industrial south-gate road), `?` east gate (sealed; the future road to
`power_station` — the last road in the city).

## Zone map (10 zones)

```
        [west block]                         [east block]
 z_relay_room (GG, the            z_transformer_yard (f, Yard C,
   fuse_substation pad)             the warm tank)
 z_control_room (K/L, mimic       z_cable_trench (m, between
   board + vault key)                the blocks)
 z_crew_bunk (T, the crew's       z_switchgear_vault (c, locked,
   last camp)                        breaker 9, never lit)
 z_gatehouse (D, entry +          z_arc_cage (o, fenced, never
   point of no return)               entered, never lit)
                                      z_lamp_boneyard (Keeper's staging)
                                      z_east_gate (?, sealed)
```

Two blocks face each other across the cable trench. The west block holds the crew's last
camp, the control room and the relay room; the east block holds the yard, the vault and
the cage; the boneyard and the sealed east gate close the district to the east — the
crew's tracks lead through the fence corner, and nothing comes back the other way.

## Per-zone plan

### z_gatehouse — entry from the industrial road, SAFE-ish (D cell)
- Props: gatehouse with the duplicate logbook in the desk drawer (`props/examine.tscn` →
  `substation_note_01`), barrier arm, road sign "Подстанция Ж-3" facing the industrial
  road, chain-link, one lamp on the gatehouse wall, `cargo_crate` ×2, fog off the yard.
- Pickups: fixed `substation_fix_exit_01` (3× battery), `substation_fix_defense_01`
  (2× noise_bomb, STREETS+, the air-horn test canisters); no rolled loot (safe-start rule).
- Stage behavior: DARK = gatehouse lamp dead; STREETS+ the wall lamp takes a low warm
  `#c9a24a` throw; the barrier stays down until the district opens (trigger). The threshold
  prose lives in the logbook (note_01), never in UI.
- Ambience: `substation_cable_hum.ogg` (0.0) faintest here — the yard's voice at a distance.

### z_transformer_yard — Yard C, the tanks (f cell)
- Props: transformer tank rows (the east-row middle tank sweats dark while the rest stand
  frosted — the `substation_note_02` subject, prop only), frost gravel, the Yard C fence
  placard with the photo pinned inside (`props/examine.tscn` → `substation_note_02`),
  `oil_drum` ×1 rolled, yard flood pair (usable `props/streetlight_3d.tscn` ×2).
- Pickups: fixed `substation_fix_yard_01` (3× scrap, the frost drum — optional risk-reward
  inside the destroyer's patrol); 2 rolled `oil_drum`.
- Stealth: DESTROYER COUNTRY — it walks the tank rows and breaks the floods it passes;
  5 m / 180° sight means the tank bodies are the cover, the hum at 12 m is the warning.
  No chain component, key or note lives only here (R1/R5).
- Ambience: `substation_transformer_buzz.ogg` (0.0) strongest here — the yard's own voice;
  `substation_arc_crackle.ogg` (5.8) bleeding from the cage fence.

### z_relay_room — the sender rack (GG cell)
- Props: `props/puzzle_3d.tscn` pad wired to `PowerSwitch` (this is `fuse_substation`),
  the relay rack with the recovered tape slotted in the sender (`props/examine.tscn` →
  `substation_note_07`, STREETS+), spool rack with drum cable, `cable_spool` ×1,
  `relay_rack` ×1 rolled, one ceiling lamp (usable ×1).
- Pickups: fixed `substation_fix_puzzle_01` (2× cable, the spool),
  `substation_fix_theme_02` (2× wiring, rack spares); 1 rolled `relay_rack`.
- Stage behavior: DARK = dead; PARTIAL = the rack takes its first pilot lights (the
  district's own circuit); FULL = sender steady — the tape could go back on the air.
- Fire discipline: no molotov/noise_bomb cache here (sender rack — R8).
- Ambience: `substation_cable_hum.ogg` (0.0) closest here; the rack itself is silent.

### z_control_room — mimic board + vault key (K/L cells)
- Props: mimic board with the night-zero printout in the printer tray
  (`props/examine.tscn` → `substation_note_04`, PARTIAL+), operator desk with the vault key
  in the unlocked drawer, fuse cabinet under the board, `fuse_cabinet` ×1,
  `office_desk` ×1 rolled, window looking out over the yard and the boneyard.
- Pickups: fixed `substation_fix_key_01` (vault key, unlocked drawer),
  `substation_fix_puzzle_02` (2× fuse, the cabinet); 1 rolled `office_desk`.
- Purpose: the key-chain start; reachable in DARK so R1 holds. The window is the one clean
  sightline over the destroyer's yard — use it to read the patrol, not to fight it.
- Stage behavior: control lamp usable from PARTIAL (the board is read by window spill
  before that).

### z_cable_trench — between the blocks (m cell)
- Props: open cable trench with busbar runs, trench covers (some lifted), cable coils,
  warning placards, one trench lamp (usable ×1), `cable_spool` ×1 rolled.
- Pickups: 1 rolled `cable_spool`.
- Stealth: HUNTER territory — the trench's straight run is a charge lane (charge 8.0 m/s
  after a 1.0 s roar windup); never strobe-and-run here, the beam's exit is the trigger
  (R5). Cross at the covers, never along the run.
- Ambience: `substation_cable_hum.ogg` (0.0) — the trench sings the yard's song up close.

### z_switchgear_vault — breaker 9, locked (c cell, **never relit — R8**)
- Props: mesh-caged breaker frames, breaker 9 wired off-plan with the vault order clipped
  to its frame (`props/examine.tscn` → `substation_note_05`, STREETS+), solid-state spare
  rack, viewing slit in the door, busbar runs entering from the relay room.
- Pickups: fixed `substation_fix_puzzle_03` (2× transistor); 1 rolled `relay_rack`
  (rich, ×1.3 — the vault's solid-state is the district's one fat cache).
- Lock: `substation_fix_key_01` from the control-room desk. Short corridor, single door —
  the DARK solvability room (R1). Never lit (R8); read by corridor spill, mirrors
  industrial's switchgear room.
- Stealth: watchers drift the corridor; the slit lets you confirm the room before you
  commit to the lock.

### z_crew_bunk — the crew's last camp (T cell)
- Props: bunk beds, footlocker with the recorder on top (`props/examine.tscn` →
  `substation_note_03`, PARTIAL+), first-aid locker, cached drums, the crew's route
  chalked on the wall (suburbs → park → here, and an arrow east), `steel_locker` ×1,
  one bunk lamp (usable ×1).
- Pickups: fixed `substation_fix_med_01` (2× medkit, the crew's stocked locker);
  1 rolled `steel_locker`.
- Stage behavior: the bunk lamp takes a low warm throw at PARTIAL — the crew's camp lit
  for whoever walks the line next.
- Ambience: quietest zone; the yard's transformer buzz arrives here −12 dB through the
  wall — a hum that is not quite a hum.

### z_arc_cage — the fault, fenced (o cell, **never entered, never lit — R8**)
- Props: chain-link arc-flash cage around the faulted busbar section, warning placards,
  scorch marks climbing the mesh, the mesh EXAMINED THROUGH ONLY — the fence stays locked
  with no key anywhere in the district; one dead flood outside the mesh (never usable).
- Pickups: none, fixed or rolled — the cage is an anomaly, not a store (R8).
- Stage behavior: at DARK the fault arcs blue-white inside the mesh (the district's cruel
  light — the only thing burning in D10 is the thing that is broken); at FULL it falls
  silent and dark, starved by the restored grid. Never a lamp, never entered.
- Ambience: `substation_arc_crackle.ogg` (5.8 dB) loudest here — the cage's own voice;
  it must never become a patrol cue, only a place.

### z_lamp_boneyard — the Keeper's staging (boneyard rows)
- Props: stacked dismantled lamp housings sorted brass-from-iron, the chalk tally board
  (prop, count unreadable past 219 by design), wire-tagged slips naming suburbs streets,
  the control-window photograph (`props/examine.tscn` → `substation_note_06`, STREETS+ —
  the photo sits taped to the control-room window but depicts this zone; examine anchor
  here at the tally board), `parts_bin` ×1, one boneyard flood (usable ×1).
- Pickups: fixed `substation_fix_theme_01` (1× transformer, staged spare);
  1 rolled `parts_bin`.
- Stealth: the destroyer's second patrol room — it walks the boneyard edge; the stacks are
  the cover. The transformer cache is reachable without crossing the patrol line (R1/R5).
- Ambience: `substation_transformer_buzz.ogg` (0.0) thin here; wind through the housings.

### z_east_gate — the sealed gate, last road (the `?` cell)
- Props: the chained east gate, works fence with the crew's cut corner (prop — mesh cut
  from inside, heading east), the gate photograph taped to the gate (`props/examine.tscn`
  → `substation_note_08`, FULL only), milestone post "Электростанция — 2", gate lamp
  (usable ×1), `cargo_crate` ×1 rolled (road staging).
- Pickups: 1 rolled `cargo_crate`. No fixed cache — the gate is a threshold, not a store.
- Stage behavior: the gate lamp takes FULL's warm throw and the gate stands open — past it
  is D11, the finale. Nothing here ever says so out loud; the photo does (note_08).
- Ambience: `substation_cable_hum.ogg` (0.0) fading east into open fog.

## Streetlight & stage-state summary

| Stage | Lights lit (of 11 usable) | Warm points | Ambience shift |
|-------|---------------------------|-------------|----------------|
| DARK (0)    | 0 (the yard is a silhouette; the destroyer breaks what burns; the cage arcs fault-blue, not warm) | none; fog holds the yard | substation_dark bed + transformer buzz + arc crackle + cable hum |
| PARTIAL (1) | 3 (gatehouse, relay room, crew bunk) | the crew's camp first — the bunk lamp for whoever walks next | hum steadies; crackle stays (the fault is still fed) |
| STREETS (2) | 7 (+ yard flood A, control room, trench, east gate) | the yard readable from the control window | buzz −6; hum warms; crackle thins |
| FULL (3)    | 11 (all: + yard flood B, boneyard, relay exterior, trench north) | the open east gate + the silent cage | warm lit layer — `substation_lit.ogg`, spec in docs/AUDIO_COVERAGE.md |

`z_switchgear_vault` stays unlit at every stage, and `z_arc_cage` is never entered and
never lit (R8). The destroyer will break relit floods on its yard patrol — that is
intended (R5): the stage table is the ceiling, not a floor; CODE should treat lamp
breakage as gameplay, not a bug to guard against.

## Art / audio gaps

1. Lit tile twins `tiles/substation_floor_lit.png` / `tiles/substation_wall_lit.png` —
   **filled by this PR's asset pass** (derived from the shipped dark twins, which are
   seam-probed first per the warehouses precedent; §4.1 numbers in
   `docs/ASSET_LICENSES.md`).
2. Substation prop faces — spec only, non-blocking (placeholder boxes / existing surfaces
   cover the zones meanwhile, mirroring the industrial pass):
   - `surfaces/breaker_panel_512.png` — caged breaker face for breaker 9 and the vault
     racks (steel mesh over panel `#141b24`, signal-yellow `#f4f45d` tags as the only
     accent, kept small per the accent rule above; matte, unlit, no text).
   - Optional: the arc-cage fault visual (scorch decal reusing
     `surfaces/metal_rust_512.png`; the arc itself is CODE/VFX, never baked into art).
3. Audio `districts/substation_lit.ogg` — **real gap**, full spec in
   `docs/AUDIO_COVERAGE.md` (G3 one-liner promoted to a full spec by this PR, not
   fabricated here). Dark bed and all 3 detail one-shots exist and are header-verified
   by this PR (see AUDIO_COVERAGE).
