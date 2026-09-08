# Prop Manifest — District `residential` (district 2)

Owner: CONTENT (this file is a placement **plan**; the CODE agent wires nodes).
Canon: GDD §4 (district loop), §4.2 (stages), §14 (perf: draw calls <200 D1, <350 D11;
<50K polys/district). Scene to wire: `scenes/districts/residential.tscn` (existing nodes:
`StreetBuilder`, `Props`, `PowerSwitch` at (8,0,8), `EmissiveWindows` seed 8547,
`DistrictTrigger`). Enemies (canon, `scripts/enemies/enemy_pool.gd`): `shadow`, `crawler` ×2.
Theme: panel-block apartment courtyards («спальный район»), permanent night, warm light
only from restored streetlights (docs/STYLE_GUIDE.md temperature principle).

Zones below are the content-side map; the same ids are used by `item_spawns.json` (`zones`)
and `lore_notes.json` (`location_hint`), so one wiring pass covers all three files. Cell
anchors reference the `DistrictLayouts` residential grid (`scripts/world/district_layouts.gd`)
advisory-style: `##` panel blocks W/E, `GG` generator pad, `m` mailboxes, `f` laundry lines,
`o` house-24 entrance, `b` boiler room, `T` playground, `S` south gate, `C` east exit.

## Zone map (8 zones)

```
            z_block_west | courtyard | z_block_east
   (## rows1-6)          |           |        (## rows1-6)
                         |           |
        z_house24 (o) ---+ z_boiler_room (b) --- z_laundry_yard (f)
                         |           |
        z_gate_south (S) | z_courtyard_play (T) | z_exit_east (C, to park)
```

## Per-zone plan

### z_gate_south — entry from suburbs, SAFE-ish
- Props: 1 flickering `props/streetlight_3d.tscn` at the gate arch (continuation of the
  suburbs exit beacon — the light the player followed north). Wrecked pram + debris piles
  (existing environment props), district entry sign (cosmetic examine, no note).
- Pickups: fixed `residential_fix_exit_01` (3× battery in `mail_box`). No rolled loot
  (safe-start, same rule as suburbs z_spawn_edge).
- Stage behavior: DARK = flicker only; STREETS+ = steady. `EmissiveWindows`: none here.

### z_block_west — west panel block, stairwell stealth (crawler teaching)
- Props: 3 entrance canopies along the west block (`##` cols 1–2, rows 1–6), boarded
  ground-floor windows, superintendent's closet door (`apartment_closet` container),
  1 overturned trash can per entrance (stealth cover vs `crawler`).
- Pickups: 2 `apartment_closet` + 1 `kitchen_drawer` containers; fixed
  `residential_fix_puzzle_02` (2× fuse).
- Examine: `props/examine.tscn` → audio_log `residential_note_03` (intercom, house 12),
  `props/examine.tscn` → document `residential_note_08` (superintendent's ledger, PARTIAL+).
- Ambience: `residential_tv_murmur.ogg` ghost layer at entrances (DARK only — the TVs no
  one pays for), `residential_window_rattle.ogg` on wind gusts (all stages).

### z_block_east — east panel block, the watching window
- Props: 3 entrance canopies (`##` cols 9–10), one 7th-floor window flagged for
  `EmissiveWindows` (the amber window of `residential_note_05`; lights at PARTIAL and
  stays lit — environmental question, never explained).
- Pickups: 1 `apartment_closet` + 1 `trash_bin` containers.
- Examine: `props/examine.tscn` → photo `residential_note_05` at the drying-rack pole
  (PARTIAL+).
- Ambience: `residential_window_rattle.ogg` stronger here (exposed side).

### z_courtyard_play — playground, safest courtyard pocket (T cell)
- Props: yard swing + sandbox (see Gaps #1 — placeholder boxes until art lands; existing
  debris props meanwhile), chalk circle on asphalt (decal or examine anchor), 1 `trash_bin`.
- Pickups: fixed `residential_fix_key_01` (boiler key in the sandbox trash_bin).
- Examine: `props/examine.tscn` → photo `residential_note_02` (wedding photo, bench),
  `props/examine.tscn` → document `residential_note_06` (chalk, PARTIAL+).
- Purpose: emotional center — the child-chalk lamp from suburbs_note_06 answered here.

### z_laundry_yard — clotheslines between blocks (f cell)
- Props: 3 clotheslines with frozen laundry silhouettes (see Gaps #2), fence segments,
  1 `laundry_basket` + 1 `mail_box` container (m-cell mailboxes at the north edge).
- Pickups: rolled loot ×2; no fixed spawns.
- Stealth: laundry sheets break line-of-sight vs `watcher`-class vision cones — teach the
  player to move between sight-blockers.
- Ambience: cloth flap = `suburbs_wind_leaves.ogg` reused at low volume is OFF-canon flavor;
  use `residential_window_rattle.ogg` only. (No new audio invented here.)

### z_house24 — Babka Manya's door (o cell)
- Props: the only door with a clean stoop, potted dead geraniums, icon lamp above the door
  (tiny warm point light, `EmissiveWindows`-independent, always on — canon: "the Keeper
  still keeps his light on" lineage; budget 1 dynamic light).
- Pickups: 2 `kitchen_drawer` containers; fixed `residential_fix_med_01` (2× medkit) and
  `residential_fix_blueprint_01` (blueprint, PARTIAL+).
- Examine: `props/examine.tscn` → document `residential_note_01` (letter under the door).
- Rule: no enemy pathing inside 6 m of the door (safe pocket; code decides radius).

### z_boiler_room — pipe gallery / transformer puzzle (b cell, locked)
- Props: rusted door (locked by `residential_fix_key_01`), pipe run along the wall,
  transformer pad `props/puzzle_3d.tscn` (the district's restore puzzle; `PowerSwitch`
  node already placed at (8,0,8) in the scene — wire the pad to it), cable spools,
  2 `basement_shelf` containers.
- Pickups: fixed `residential_fix_puzzle_01` (2× cable) + `residential_fix_puzzle_03`
  (2× transistor) — the grid-crew cache of `residential_note_07`.
- Examine: `props/examine.tscn` → document `residential_note_04` (pipe gallery notice)
  on the outside of the door (readable before the key).
- Ambience: `residential_pipe_creak.ogg` proximity loop, interior only (all stages; the
  pipes "count" whether powered or not).

### z_exit_east — exit to `park` (C cell)
- Props: barricade with a passage, road sign "Парк →", last streetlight of the district
  (`props/streetlight_3d.tscn`, part of the 6 usable — not a free beacon like suburbs').
- Pickups: fixed `residential_fix_defense_01` (2× molotov, STREETS+).
- Examine: `props/examine.tscn` → audio_log `residential_note_07` (grid crew log 3, STREETS+).
- Purpose: hands the player the next district's dread — the park is darker.

## Streetlight & stage-state summary (wire into `PowerSwitch` / `PowerGrid`)

| Stage | Streetlights lit (of 6 usable) | EmissiveWindows | Ambience shift |
|-------|-------------------------------|-----------------|----------------|
| DARK (0)   | 0 + flicker at gate        | 0 (watching window off) | residential_dark bed + pipe creak + tv murmur (DARK only) + window rattle |
| PARTIAL (1)| 2 (courtyard ring)          | watching window + 2 entrances | tv murmur fades out |
| STREETS (2)| 4                            | + 4 entrances    | window rattle calms (wind dies with power hum) |
| FULL (3)   | 6 + gate steady              | all mapped       | warm lit layer (GDD §4.2 "LIT звучит теплее"); pipe creak remains (canon) |

## Content gaps (art/audio — prompts tracked in docs/STYLE_GUIDE.md + docs/ASSET_LICENSES.md)

1. Playground prop set (yard swing, sandbox, chalk decal) — `z_courtyard_play`. No scene in
   `scenes/props/` covers it; placeholder debris until CODE/art lands a `playground_3d` prop.
2. Clothesline prop with frozen laundry silhouette — `z_laundry_yard` (sight-blocker).
3. Lit tileset `tiles/residential_floor_lit.png` / `residential_wall_lit.png` — **filled by
   this pass** (generated, recorded in docs/ASSET_LICENSES.md).
4. Audio: `districts/residential_lit.ogg` warm restored bed — gap list in
   docs/AUDIO_COVERAGE.md (not fabricated here).
5. Panel-block facade variant with entrance canopy + 7th-floor window cutout —
   `z_block_west` / `z_block_east` (reuse `tiles/residential_wall.png` meanwhile).
