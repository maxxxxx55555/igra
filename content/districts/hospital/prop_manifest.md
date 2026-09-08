# Prop Manifest — District `hospital` (district 5)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §12.3 (**Act II gate** — the Project Architect
reveal opens at hospital STREETS), §14 perf. Scene to wire: `scenes/districts/hospital.tscn`
(same node contract as siblings: `StreetBuilder`, `Props`, `PowerSwitch`, `EmissiveWindows`,
`DistrictTrigger`). Opens at residential FULL (`district_hospital.tres`
`powered_by = [&"residential"]`); hospital in turn powers `warehouses`.
Enemies (canon, `enemy_pool.gd`): `watcher`, `shadow`, `crawler` — watcher leads the roster.
Theme (`district_themes.gd`): primary `#5a5a6a`, accent `#5dc8f4` (the only teal-accent
district — STYLE_GUIDE §2 reserves teal for information, which is exactly what this district
is), sky `#0b0c11`, ambient `#14151c`.
Puzzle canon: `puzzle_system.gd` `generator_hospital` (reward 1 medkit, `power_stage` 2).

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference the `DistrictLayouts` hospital grid advisory-style:
`####` two wings, `GG` diesel plant pad, `K` records/archive, `L` lamp, `T` morgue stair,
`m` ward corridor head, `b` ward B, `f` operating suite, `o` pharmacy, `S` south gate.

## Zone map (10 zones)

```
        [west wing]                         [east wing]
 z_generator_room (GG)   z_ward_corridor (m)   z_ward_b (b)
 z_records (K)           z_reception           z_operating (f)
 z_morgue (T, below)                           z_pharmacy (o)
 z_ambulance_bay (from residential)     z_exit_south (S, -> warehouses road)
```

Everything except the bay is interior; the flashlight is the only light the player owns
until PARTIAL, and the district's own lamps are the objects the lore keeps warning about.

## Per-zone plan

### z_ambulance_bay — entry from residential, SAFE-ish
- Props: canopy over six bay lanes, one wrecked ambulance with open rear doors, gurney with
  tray (`gurney_tray` container), dispatch window with the photo (`props/examine.tscn` →
  `hospital_note_02`), 1 flickering `props/streetlight_3d.tscn` on the canopy bracket.
- Pickups: fixed `hospital_fix_exit_01` (3× battery). No rolled loot (safe-start rule).
- Stage behavior: DARK = flicker; STREETS+ steady; FULL adds the red bay sign as a baked
  emissive strip (ember `#b4452f` is danger-only per STYLE_GUIDE §2 — use it here at low
  energy, it is literally an emergency sign).
- Ambience: `hospital_elevator_distant.ogg` bleeding out of the building (0.0 dB offset).

### z_reception — triage hall, hub
- Props: reception desk with the triage board (`props/examine.tscn` → `hospital_note_01`),
  waiting-row chairs, collapsed queue barriers, night drawer (`bedside_locker` container),
  wall clock stopped at 03:40 (the school's counting hour — quiet cross-district rhyme).
- Pickups: fixed `hospital_fix_key_01` (pharmacy key); 1 rolled `bedside_locker`.
- Ambience: `hospital_pa_mumble.ogg` (2.4 dB) loudest here — the PA still has residual power.
- Stealth: three exits; the district's re-entry pocket, like the school lobby.

### z_ward_corridor — the spine (m cell)
- Props: `tiles/hospital_floor.png` / `hospital_wall.png` corridor, nurses' station trolley
  with the dictaphone (`props/examine.tscn` → `hospital_note_03`, PARTIAL+), wall-mounted
  `first_aid_cabinet`, overturned wheelchairs, hanging drip stands.
- Pickups: fixed `hospital_fix_puzzle_02` (2× fuse); 2 rolled containers.
- Ambience: `hospital_gurney_wheels.ogg` (0.0 dB) one-shots from the far end on a 30–70 s
  timer; `hospital_monitor_beep.ogg` (4.6 dB) as isolated single beeps, never a rhythm.
- Stealth: long sightlines, but the alcoves between ward doors give cover — the corridor is
  *walkable* in DARK, which `hospital_note_03` states in-world ("a light that walks").

### z_ward_b — patient ward, curtains (b cell)
- Props: eight beds with privacy curtains on rails (`surfaces/hospital_curtain_512.png`,
  generated this pass), window bed with the chart holder (`props/examine.tscn` →
  `hospital_note_04`), `linen_cart`, `supply_trolley`, restraint straps still buckled.
- Pickups: fixed `hospital_fix_med_01` (2× medkit), `hospital_fix_craft_02` (3× fabric);
  1 rolled `bedside_locker`.
- Stealth: curtains are the district's soft cover — they break line of sight without
  blocking sound; crawler patrol space under the beds.

### z_operating — surgical suite (f cell)
- Props: operating table under a dead multi-head lamp, instrument trolleys, scrub sinks,
  x-ray light box on the wall (`surfaces/xray_lightbox_512.png`, generated this pass),
  spirit crate (`supply_trolley`).
- Pickups: fixed `hospital_fix_craft_01` (2× alcohol); 1 rolled `supply_trolley`.
- Stage behavior: at FULL the operating lamp comes back — the only cold-white-adjacent
  light in the game; keep it at teal-tinted `#5dc8f4` low energy, never white (STYLE_GUIDE §2).
- Stealth: single entrance, no cover — the R5 risk/reward room.

### z_pharmacy — locked drug store (o cell)
- Props: steel mesh door (locked, `hospital_fix_key_01`), `pharmacy_cabinet` shelving ×2,
  spill of blister packs, ledger clipboard (cosmetic).
- Pickups: fixed `hospital_fix_puzzle_03` (2× transistor), `hospital_fix_med_02`
  (1× serum, PARTIAL+); rolls are non-empty by R6.
- Purpose: the key-chain payoff and the start of the serum economy (R2).

### z_records — archive, the Act II room (K cell)
- Props: collapsed shelving rows, archive boxes (`archive_box` container ×2), microfiche
  reader, x-ray light box with the photo behind it (`props/examine.tscn` →
  `hospital_note_07`, STREETS+), box 14 open on the floor (`props/examine.tscn` →
  `hospital_note_06`, STREETS+).
- Pickups: 2 rolled `archive_box`.
- Ambience: room tone only; drop the detail beds to −12 dB here so the two documents land
  in silence.
- **Gate:** nothing in this room may be readable before STREETS (item_spawns R7).

### z_generator_room — diesel plant + transformer pad (GG cell)
- Props: `props/puzzle_3d.tscn` pad wired to `PowerSwitch` (this is `generator_hospital`),
  diesel plant with `surfaces/generator_metal_512.png`, `surfaces/fusebox_512.png` panel,
  control desk with the recorder (`props/examine.tscn` → `hospital_note_05`, PARTIAL+),
  cable runs — including the *fourth* feeder disappearing into the wall toward the park
  line (a prop the player can look at but not follow; it pays off in `z_records`).
- Pickups: fixed `hospital_fix_puzzle_01` (2× cable); 1 rolled `supply_trolley`.
- Ambience: `substation_cable_hum.ogg` at −10 dB (existing file reused, no new audio).

### z_morgue — below the west wing (T cell)
- Props: drawer bank wall (`surfaces/morgue_drawers_512.png`, generated this pass),
  attendant's desk with the ledger (`props/examine.tscn` → `hospital_note_08`, FULL only),
  trolley, drain floor using `surfaces/hospital_tile_dirty_512.png`.
- Pickups: 1 rolled `morgue_drawer` (0.8 modifier — grim, poor, deliberate).
- Stage behavior: like the school shelter, the morgue is **never relit**. At FULL the stair
  head gets one working lamp; the room below stays dark.
- Ambience: dead air; a single `hospital_monitor_beep.ogg` at −18 dB every 90–150 s.

### z_exit_south — south gate toward the warehouses road (S cell)
- Props: barrier arm, road sign "Склады →", last usable streetlight, `trash_bin`.
- Pickups: fixed `hospital_fix_defense_01` (2× molotov, STREETS+).

## Streetlight & stage-state summary

| Stage | Lights lit (of 6 usable) | Warm points | Ambience shift |
|-------|--------------------------|-------------|----------------|
| DARK (0)    | 0 + bay flicker      | none (flashlight only) | hospital_dark bed + PA mumble + gurney wheels + isolated beeps |
| PARTIAL (1) | 2 (reception, corridor half) | reception desk lamp | monitor beeps gain a slow rhythm |
| STREETS (2) | 4 (corridor full, records) | corridor ceiling bank | PA mumble resolves into almost-words, then stops |
| FULL (3)    | 6 (+ operating lamp, bay sign) | operating lamp (teal), bay sign (ember, low) | `hospital_lit.ogg` (already shipped ✔) |

`z_morgue` is exempt from every row: always unlit.

## Art / audio gaps

1. `tiles/hospital_floor_lit.png` / `hospital_wall_lit.png` — **already shipped** (verified
   on disk); no lit-tile work needed for this district.
2. Privacy-curtain surface `surfaces/hospital_curtain_512.png` — **filled by this pass**.
3. X-ray light box surface `surfaces/xray_lightbox_512.png` — **filled by this pass**.
4. Morgue drawer bank surface `surfaces/morgue_drawers_512.png` — **filled by this pass**.
5. Gurney / drip-stand / wheelchair props — placeholder boxes until art lands (no blocking
   dependency; existing debris props cover the zones meanwhile).
6. Audio: `districts/hospital_lit.ogg` **exists and was statically verified** (mono,
   44.1 kHz, exactly 36.000 s) — see `docs/AUDIO_COVERAGE.md`; the only hospital audio item
   left is the optional detail bed listed there (spec only, not fabricated).
