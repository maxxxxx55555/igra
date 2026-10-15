# Map density plan (Session 23, D1)

The question of D1: does any part of any district stand empty, and what fills it from the assets the project already has? Nothing here is a new binary:
every piece is a primitive mesh, one of three meshes that were already in the tree (`_BIN`, `_HYDRANT` and `_BENCH` in `scripts/world/district_dressing.gd:7-9`) or a
script that builds from them. Everything is visual only: no collision except the iron covers of the roads (a 1 cm plate, flush), no navigation, so no path of the
spine, no pickup and no monster route moves (the monsters walk a plain 80 x 80 navigation mesh and `move_and_slide`).

## 1. The audit (D1.1, no launch of its own)

A zone is a **block**: one of the nine 16 m cells between the road axes of a district's street grid (`GRID_M` in `scripts/tools/rc16/density_checks.gd:11`; the
roads run at x and z of -24, -8, 8 and 24, so the cells are -24..-8, -8..8 and 8..24 on each axis). The check DENS1 builds each of the eleven district scenes
at the origin (where the game builds them), counts what stands in each block and takes the least over the nine blocks:

| Class | What counts | Floor per block |
|---|---|---|
| solid | benches, tree trunks, cones, crates, barrels, bins, hydrants (`SOLID` in `scripts/tools/rc16/density_checks.gd:12`) | 2 (`FLOOR_SOLID`, line 8) |
| scatter | litter and leaves, soft wet patches (`SCATTER`) | 4 (`FLOOR_SCATTER`, line 9) |
| lamps | streetlamp poles (`LAMPS`) | 2 (`FLOOR_LAMPS`, line 10) |

The deficit before this pass: the same count with the dressing node left out (what shipped in `v8.0.0-shipping`) is **0 solid props and 0 scattered pieces in the
emptiest block of every one of the eleven districts**: the street furniture stood on the sidewalks and the nine block interiors were black voids. Lamps were
never the problem (4 in the emptiest block). Launch 109 (`s23_closeout_7b63426`, ledger row 109, `docs/artifacts/rc16/proofs/s23_closeout_7b63426.out`):

| District | Solid, least per block (without the dressing) | Scatter (without) | Lamps | Draw calls in the audit view, without, with | Landmark |
|---|---|---|---|---|---|
| suburbs | 4 (0) | 12 (0) | 4 | 99, 112 | water tower |
| residential | 3 (0) | 12 (0) | 4 | 111, 124 | apartment tower with lit floors and a mast |
| park | 2 (0) | 16 (0) | 4 | 97, 108 | ferris wheel |
| school | 5 (0) | 12 (0) | 4 | 119, 132 | clock tower |
| hospital | 4 (0) | 5 (0) | 4 | 108, 121 | tower with a lit cross and a helipad |
| gas_station | 6 (0) | 10 (0) | 4 | 107, 122 | price pylon and a canopy |
| police | 6 (0) | 6 (0) | 4 | 107, 122 | radio mast and the station |
| warehouses | 7 (0) | 8 (0) | 4 | 107, 125 | gantry crane |
| industrial | 7 (0) | 8 (0) | 4 | 116, 134 | smokestacks |
| substation | 3 (0) | 5 (0) | 4 | 106, 122 | pylon and two transformers |
| power_station | 6 (0) | 6 (0) | 4 | 103, 121 | two cooling towers and a stack |

The draw calls are the windowed readings of launch 108 (`s23_d1_final_f49dd9d`, the `[density] perf` lines of its density log) at the fixed audit view of each
district: the dressing costs 11 to 18 draw calls (mean 14.8), 13 batched nodes, so the busiest district (industrial, 134) stays under the D11 budget of 350 and the
dressing alone is a tenth of the D1 budget of 200. The windowed perf gate (`scripts/tools/_perf_check_runner.gd`) judges the spawn view at the final hash.

**Backlog of other agents (D1.1):** none exists. The 32 remote branches were read: 19 are merged into `main`, the 13 that are not carry the August test and fix commits of
the first arena, art plates of October and agent notes (`docs/ARENA_CLOSURE.md`); `git log --remotes --grep` for prop placement, density, dressing, per-zone and empty zone finds only this pass's own commits.

## 2. The kit (D1.2, from `KIT` in `scripts/world/district_dressing.gd:44`)

Per block and per district: litter pieces, leaves, wet patches, crates, barrels, bins. The streams are seeded by the district's name, so a district looks the same
every run and no other placement moves; a solid piece keeps 1.8 m (`KEEP_CLEAR_M`, line 17) from every node of the groups `interactable` and `hiding_spot`
(`_solid_spot`, line 186; `_keep_clear`, line 192), which is also what keeps a pickup and a hiding place reachable.

| District | Litter | Leaves | Puddles | Crates | Barrels | Bins | Reading |
|---|---|---|---|---|---|---|---|
| suburbs | 6 | 6 | 2 | 1 | 0 | 2 | a quiet street, fallen leaves |
| residential | 8 | 4 | 2 | 1 | 0 | 2 | more litter than leaves |
| park | 3 | 12 | 2 | 0 | 0 | 1 | the most leaves, the least litter |
| school | 8 | 3 | 2 | 2 | 0 | 2 | |
| hospital | 5 | 0 | 2 | 1 | 0 | 3 | the most bins |
| gas_station | 8 | 0 | 3 | 2 | 2 | 2 | oil drums |
| police | 6 | 0 | 2 | 2 | 1 | 2 | |
| warehouses | 7 | 0 | 3 | 4 | 2 | 1 | the most crates |
| industrial | 7 | 0 | 3 | 2 | 4 | 1 | the most barrels |
| substation | 4 | 0 | 2 | 1 | 2 | 0 | sparse |
| power_station | 5 | 0 | 3 | 2 | 2 | 1 | |

On top of the kit, in every district: five hydrants (`HYDRANTS`, line 18), a pool of light under each streetlamp that reaches into the block beside it and rises
with the power stage (`POOL_BY_STAGE`, line 27), up to two iron manhole covers in the roads round the middle block with a thread of steam rising from each
(`MANHOLES`, line 20; `_add_manholes`, line 266; they ring "metal" under the footsteps), the landmark behind the skyline ring (`PARTS` in
`scripts/world/district_landmark.gd:23`), a lit rest spot, and in the four fog districts three drifting fog cards (`FOG_DISTRICTS`, line 30) that thicken with the
power stage (`FOG_BY_STAGE`, line 34). The street trees' canopies sway (`SWAY_M`, `scripts/world/street_props.gd:280`), and stop with Motion Comfort.

## 3. Rest spots (D1.4)

One lit bench with a lantern stands by the power switch in every district (`_add_rest_spot`, line 310; `REST_FROM_SWITCH`, line 37): the switch is where the
Keeper stops to restore a district, so the place of the save flow is the place that is lit in every stage. DENS1 reads that every district holds a lantern with
its light (11 of 11).

## 4. Verticality (D1.3): an owner row

No scene of the project holds rooftop or sewer geometry that is unreachable and could be opened with a ladder: the buildings are a backdrop ring and the
landmark a silhouette behind it (`scripts/world/skyline.gd`, `scripts/world/district_landmark.gd`), and the only underground element is the manhole cover, a
plate. Adding a reachable roof needs new level geometry, a second navigation layer for the monsters and a camera pass; it is not built blind. **Owner row V1:**
spec for the first reachable roof (the school: the clock tower stair), with a navigation layer and a frame for each of the 13 locales' HUD.

## 5. What is not filled (D1.6): honest rows

- **Void blocks outside the fog districts.** The blocks hold props, litter, pools of light and a landmark behind them, but their interiors are dark ground where no
  lamp reaches; a ground haze there would cost fill rate that the dev iGPU does not have (the windowed reading at the final head is a p95 of 35.00 ms against the budget of 33 ms, red: `docs/PERF_PASS.md:19`; 28.79 ms at `v8.0.0-shipping`, `docs/PERF_PASS.md:49`). Owner row D1-a: a baked light
  pass or an art pass of interiors (a shop front, a fence, a hedge as a navigation-safe collision) per district.
- **No collision buildings in the blocks**, so nothing hides a monster's route: collision in a block changes where the monsters can walk, and the three-seed bot
  (the IRON RULE) is the only proof of that; the dressing is visual so the bot's wins hold. Owner row D1-b.
- **The lighting mood is a cluster, not a district** (`docs/DISTRICT_SIGNATURES.md`).

## 6. The frames and the numbers

The BEFORE frames are the 55 stills of the first shot (`docs/stills/density`, `*_before_5d30659_*`: five views of each district, from fixed places, in English with
the HUD and the tutorial hidden); the AFTER frames are shot at the final hash of the pass. The measured deltas, the district spread and how each was computed:
`docs/DENSITY_MEASURED.md` (`python tools/qa_sim/density_measure.py <hash> --base 5d30659`). The public list of what was tried and dropped is the S23-D1 rows of
`docs/RUN_STATE.md` (facade palettes with warm tints lost the silhouette against the sky and were replaced by tints that keep the blue lift; the first rest view
stood on the power switch's cabinet and was moved).
