# Prop Manifest — District `school` (district 4)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §12.3 (Act II opens at D4 — documents start
turning), §14 perf. Scene to wire: `scenes/districts/school.tscn` (same node contract as
siblings: `StreetBuilder`, `Props`, `PowerSwitch`, `EmissiveWindows`, `DistrictTrigger`).
Opens at residential FULL (`district_school.tres` `powered_by = [&"residential"]` — verified,
**not** park). Enemies (canon, `scripts/enemies/enemy_pool.gd`): `shadow`, `crawler`,
`watcher`. Theme (`district_themes.gd`): primary `#5a5a6a`, accent `#f4c95d`, sky `#0b0c11`,
ambient `#14151c` — cold institutional interior, permanent night.
Puzzle canon: `puzzle_system.gd` `switch_school` (reward 100 coins, `power_stage` 2).
Quest canon: `quest_manager.gd` `q_explore_school` (EXPLORE, zone id `school_zone`).

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference the `DistrictLayouts` school grid advisory-style:
`####` two closed wings, `GG` generator/boiler pad, `K` caretaker's room, `L` lamp,
`T` shelter stair head, `m` gym hall, `b` cafeteria, `oo` classroom wing, `C` south yard gate.

## Zone map (9 zones)

```
        [west wing]                      [east wing]
 z_boiler_room (GG,K)   z_gym (m)    z_classroom_wing (oo)
 z_basement_shelter (T) z_lobby      z_cafeteria (b)
        z_corridor_lockers (L, spine between the wings)
 z_yard_gate (C, from residential)     z_exit_north (-> hospital road)
```

The building reads as a ring: yard → lobby → corridor spine → wings → boiler room →
shelter. Every zone except the yard is interior, so the flashlight is the only light the
player owns until PARTIAL.

## Per-zone plan

### z_yard_gate — entry from residential, SAFE-ish
- Props: yard gate with the collection notice board (`props/examine.tscn` →
  `school_note_04`), bus-stop bollards, flag pole with no flag, 1 flickering
  `props/streetlight_3d.tscn` over the gate, 1 `trash_bin`.
- Pickups: fixed `school_fix_exit_01` (3× battery). No rolled loot (safe-start rule, as in
  suburbs `z_spawn_edge` / residential `z_gate_south`).
- Stage behavior: DARK = flicker only; STREETS+ steady; FULL = yard flood on the wall bracket.
- Ambience: `suburbs_wind_leaves.ogg` thinned out at −6 dB (outdoor pocket, existing file).

### z_lobby — entrance hall, duty desk, first interior
- Props: duty desk with the board (`props/examine.tscn` → `school_note_01`), trophy case
  (`trophy_case` container), coat hooks with 40 identical coats, first-aid cabinet
  (`first_aid_cabinet`), floor of `tiles/school_floor.png`.
- Pickups: fixed `school_fix_med_01` (2× medkit); 1 rolled `trophy_case`.
- Ambience: `school_bell_echo.ogg` (offset 1.8 dB per `district_atmosphere.gd`) is loudest
  here — the bell relay still trips on the dead clock line.
- Stealth: two exits (yard / corridor); the safe re-entry pocket of the district.

### z_corridor_lockers — the spine, watcher lane
- Props: double locker rows (`tiles/school_wall.png` is literally this locker wall),
  caretaker's notice frame (`props/examine.tscn` → photo `school_note_02`), fallen
  ceiling-lamp diffusers, a mop bucket; 3 `locker` containers.
- Pickups: fixed `school_fix_puzzle_01` (2× cable), `school_fix_lure_01` (2× noise_bomb);
  2 rolled `locker`.
- Ambience: `school_locker_slam.ogg` (2.7 dB) one-shots on a 25–60 s timer, always from the
  far end of the corridor, never from the player's segment.
- Stealth (the district lesson): the corridor is one long sightline with no cover except
  the locker recesses. `watcher_3d.gd` stuns 2 s in the flashlight beam and then rages
  (×1.25 speed) — the correct play is light off, walk, or throw a noise_bomb past it.
  `school_note_03` states the rule in-world before the player meets one.

### z_classroom_wing — classrooms (oo cells)
- Props: desk grid with chairs on tables, chalkboard with the tally (examine anchor →
  `school_note_06`, STREETS+), globe, wall map, 2 `desk_drawer` containers.
- Pickups: fixed `school_fix_paper_01` (3× paper); 1 rolled `desk_drawer`.
- Ambience: `school_chalk_scratch.ogg` (0.0 dB) rare one-shots, only in DARK/PARTIAL —
  the board writes at 03:40 and the sound is the only proof.
- Stealth: dense desk cover, short sightlines — the safe, poor half of R5.

### z_gym — gymnasium, the shelter camp (m cell)
- Props: wall bars, folded cots in rows, hung kerosene lanterns (unlit props — canon:
  no electric light in the hall), scoreboard with the photo behind glass
  (`props/examine.tscn` → `school_note_05`, PARTIAL+), cot with the tape recorder
  (`props/examine.tscn` → audio_log `school_note_03`, PARTIAL+), equipment bin (`gym_bin`).
- Pickups: fixed `school_fix_key_01` (shelter key); 1 rolled `gym_bin`.
- Stage behavior: at FULL the ceiling floods come back on ONE bank only — the caretaker's
  switching order in `school_note_08` (boiler → corridor → gym → yard) is the excuse.
- Ambience: `school_desk_scrape.ogg` (0.0 dB) used sparsely here as cot-frame scrape.

### z_cafeteria — canteen and kitchen (b cell)
- Props: bench tables, serving line with the `kitchen_pass` container, dead walk-in door,
  ration crates, service door to the boiler room (unlocked — R1 depends on it).
- Pickups: 2 rolled containers (`kitchen_pass`, `trash_bin`).
- Ambience: `school_desk_scrape.ogg` on bench legs; distant `school_bell_echo.ogg` at −6 dB.
- Stealth: table rows break the room into three lanes; crawler patrol space.

### z_boiler_room — heating plant + transformer pad (GG/K cells)
- Props: `props/puzzle_3d.tscn` transformer pad wired to `PowerSwitch` (this is
  `switch_school`), boiler with the heating risers that carry the counting, caretaker's
  bench with the ledger (`props/examine.tscn` → `school_note_08`, FULL only), parts shelf
  (`tool_cage`), `surfaces/fusebox_512.png` panel, pipe runs to the shelter.
- Pickups: fixed `school_fix_puzzle_02` (2× fuse); 1 rolled `tool_cage`.
- Ambience: `substation_cable_hum.ogg` at −10 dB as the boiler feeder hum (existing file,
  reused; no new audio required), plus `amb_lamp_hum` behaviour once the pad is powered.
- Purpose: the district's power puzzle and the physical link to the shelter — the pipes the
  voice travels through are modelled here and reappear in `z_basement_shelter`.

### z_basement_shelter — where the 300 were (T cell, locked)
- Props: shelter door with hasp lock (opened by `school_fix_key_01`), bench rows, chalked
  class numbers on the wall, heating riser with the toy recorder
  (`props/examine.tscn` → audio_log `school_note_07`, STREETS+), shelf rack
  (`shelter_shelf`), lantern stubs.
- Pickups: fixed `school_fix_puzzle_03` (2× transistor); no rolled containers (R6).
- Ambience: no district detail bed plays here except a low-passed `school_bell_echo.ogg`
  at −14 dB, heard *through* the ceiling — dead-air room by design.
- Stage behavior: stays dark at every stage. The shelter is never relit; at FULL the stair
  head gets one working bulb and the room below is still black. Deliberate.

### z_exit_north — exit to the hospital road
- Props: barricade + passage, road sign "Больница →", last usable streetlight, `trash_bin`.
- Pickups: fixed `school_fix_defense_01` (2× molotov, STREETS+).
- Purpose: narrative handoff into Act II proper (Architect reveal gates at hospital
  STREETS — nothing here may pre-empt it).

## Streetlight & stage-state summary

| Stage | Lights lit (of 6 usable) | Warm points | Ambience shift |
|-------|--------------------------|-------------|----------------|
| DARK (0)    | 0 + gate flicker    | none (flashlight only) | school_dark bed + bell echo + locker slams + chalk scratch |
| PARTIAL (1) | 2 (lobby, corridor half) | lobby desk lamp | locker slams −3 dB, chalk scratch keeps |
| STREETS (2) | 4 (corridor full, cafeteria) | corridor ceiling bank | chalk scratch stops (the board goes quiet) |
| FULL (3)    | 6 (+ gym bank, yard flood) | gym bank, yard flood | warm lit layer (`school_lit.ogg`, spec in docs/AUDIO_COVERAGE.md) |

Shelter (`z_basement_shelter`) is exempt from every row above: always unlit.

## Art / audio gaps

1. Lit tile twins `tiles/school_floor_lit.png` / `tiles/school_wall_lit.png` —
   **filled by this pass** (generated, recorded in `docs/ASSET_LICENSES.md`).
2. Locker-corridor prop surface `surfaces/school_lockers_512.png` (locker door face for
   3D prop meshes, distinct from the 256² tile) — **filled by this pass**.
3. Chalkboard surface `surfaces/chalkboard_512.png` for the classroom examine anchor —
   **filled by this pass**.
4. Cot / kerosene-lantern props for `z_gym` — placeholder boxes until art lands (no
   blocking dependency; the zone works with existing debris props).
5. Audio `districts/school_lit.ogg` — full spec in `docs/AUDIO_COVERAGE.md` (**not**
   fabricated here).
6. Optional 5th detail bed `school_pipe_whisper.ogg` (the counting, felt not heard) —
   spec only, see AUDIO_COVERAGE optional section.
