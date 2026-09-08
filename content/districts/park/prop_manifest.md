# Prop Manifest — District `park` (district 3)

Owner: CONTENT (placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §12.3 (Act I closes at D3 — the radio voice),
§14 perf. Scene to wire: `scenes/districts/park.tscn` (same node contract as siblings:
`StreetBuilder`, `Props`, `PowerSwitch`, `EmissiveWindows`, `DistrictTrigger`).
Opens at suburbs FULL (`district_park.tres` powered_by). Enemies (canon,
`scripts/enemies/enemy_pool.gd`): `crawler`, `hunter`, `shadow`.
Theme (`district_themes.gd`): primary `#3a6a4a`, accent `#f4e35d`, sky `#0a110a`,
ambient `#12180f` — bare winter trees, frozen pond, permanent night.

Zone ids are shared with `item_spawns.json` (`zones`) and `lore_notes.json`
(`location_hint`). Cell anchors reference `DistrictLayouts` park grid advisory-style:
`d` tree clusters, `GG` generator pad, `K` keeper's shed, `m` bandstand, `T` carousel,
`b` chess pavilion, `?` west gate, `W` frozen pond.

## Zone map (9 zones)

```
 z_alley_bare (dd W)      z_carousel (T)      z_grove_east (dd E)
                          z_keeper_shed (K)
 z_gate_west (?)          z_bandstand (m)     z_pond (W)
                          z_chess_grove (b)   z_exit_east (-> school)
```

## Per-zone plan

### z_gate_west — entry from residential, SAFE-ish
- Props: park entry arch with the closure notice board (`props/examine.tscn` →
  `park_note_04`), rusted turnstiles, 1 flickering `props/streetlight_3d.tscn` at the gate.
- Pickups: fixed `park_fix_exit_01` (3× battery in `mail_box`). No rolled loot (safe-start).
- Stage behavior: DARK = flicker only; STREETS+ steady.

### z_alley_bare — west tree alleys, the hunter lane
- Props: bare tree rows (existing foliage-less trunks or placeholder poles), leaf litter
  piles, 1 `trash_bin`; branch litter that cracks underfoot (noise teaching surface).
- Pickups: fixed `park_fix_lure_01` (2× firework).
- Examine: `props/examine.tscn` → audio_log `park_note_03` in the hollow stump (STREETS+).
- Ambience: `park_bare_trees_wind.ogg` base + `park_branch_snap.ogg` one-shots on a 30–70 s
  timer; `park_leaves_skitter.ogg` when the player walks (code: tie to footstep surface).
- Stealth: trunks break line-of-sight; running here draws the hunter (R5).

### z_grove_east — east tree clusters, quiet mirror of the alley
- Props: denser trunks, a fallen bench, leaf piles (cover vs crawler).
- Pickups: 1 `trash_bin` rolled loot; no fixed spawns.
- Ambience: same tree kit, branch snaps rarer (20% of west rate).

### z_keeper_shed — the Keeper's workshop (K cell, locked)
- Props: wooden shed with a streetlight-reflector wall trophy, work bench, parts shelves
  (`tool_chest` ×2), shortwave radio (examine anchor), `props/puzzle_3d.tscn` transformer
  pad wired to `PowerSwitch`; door locked by `park_fix_key_01`.
- Pickups: fixed `park_fix_puzzle_01` (cable), `park_fix_puzzle_03` (transistor),
  `park_fix_blueprint_01` (blueprint, PARTIAL+).
- Examine: `props/examine.tscn` → document `park_note_06` (work orders, PARTIAL+),
  `props/examine.tscn` → audio_log `park_note_07` (radio loop, readable in DARK).
- Ambience: faint `amb_lamp_hum.wav` (sfx) inside — the only warm room in the park.
- Purpose: Act I radio voice source; the shed is the content anchor for `char_keeper`.

### z_bandstand — manifesto monument (m cell)
- Props: rotting bandstand with rail, torn bunting, wax-seal stencil props.
- Examine: `props/examine.tscn` → document `park_note_01` (manifesto).
- Pickups: none (monument, not loot).
- Stage behavior: at FULL, `EmissiveWindows`-style string lights on the rail (one baked
  light strip, no dynamic light cost).

### z_carousel — dead carousel (T cell)
- Props: carousel platform with tarp-covered horses (placeholder boxes until art lands —
  see Gaps #1), ticket booth with `park_note_02` photo in the window.
- Pickups: 1 `trash_bin` rolled loot.
- Ambience: `park_distant_city_hum.ogg` low here (open lawn).

### z_chess_grove — chess pavilion (b cell)
- Props: 3 concrete chess tables, mid-game board (examine anchor), bench with loose boards
  (`cache_bench` container).
- Examine: `props/examine.tscn` → document `park_note_08` (PARTIAL+).
- Pickups: fixed `park_fix_puzzle_02` (fuse under the boards).

### z_pond — frozen pond (W cell)
- Props: frozen pond plane with `surfaces/pond_ice_512.png` (generated this pass — Gap #3
  filled), boat house shell, `boat_bin` container, reed clumps at the edge.
- Examine: `props/examine.tscn` → photo `park_note_05` at the boat house (PARTIAL+).
- Ambience: `park_distant_city_hum.ogg` strongest at the open ice; ice-crack one-shots =
  reuse `park_branch_snap.ogg` at −6 dB pitched down is CODE's call (no new audio here).
- Stealth: open ice = maximum visibility, no cover — risk/reward crossing to the boat house.

### z_exit_east — exit to `school`
- Props: barricade + passage, sign "Школа →", last usable streetlight.
- Pickups: fixed `park_fix_defense_01` (2× molotov, STREETS+).
- Purpose: handoff to the school's darker interior dread.

## Streetlight & stage-state summary

| Stage | Streetlights lit (of 5 usable) | Warm points | Ambience shift |
|-------|-------------------------------|-------------|----------------|
| DARK (0)   | 0 + gate flicker          | shed lamp hum only | park_dark bed + trees wind + branch snaps + leaves skitter |
| PARTIAL (1)| 2 (central lawn ring)     | + bandstand off, shed warm | city hum softens |
| STREETS (2)| 4                          | bandstand rail strip | branch snaps halve (trees "calm") |
| FULL (3)   | 5 + gate steady            | rail strip + carousel marquee baked | warm lit layer; GDD §4.2 |

## Content gaps

1. Carousel prop (tarp-covered horses, ticket booth) — `z_carousel`; placeholder until art.
2. Bandstand prop with rail + bunting — `z_bandstand`.
3. Frozen pond surface `surfaces/pond_ice_512.png` — **filled by this pass** (generated,
   recorded in docs/ASSET_LICENSES.md).
4. Lit tileset `tiles/park_floor_lit.png` / `park_wall_lit.png` — **filled by this pass**.
5. Audio `districts/park_lit.ogg` — full spec in docs/AUDIO_COVERAGE.md (not fabricated).
