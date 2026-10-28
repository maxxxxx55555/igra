# Asset Licenses — provenance & attribution ledger

Owner: CONTENT/assets agent. **Every binary added or changed in this repo is recorded here
before it is committed** (Play Store / store compliance). Policy: assets are (a) generated
in-house, (b) AI-generated in-session from in-house references, or (c) sourced from the web
under CC0/CC-BY with attribution recorded. No other origins are permitted. Sourced CC-BY
entries must also appear in the store credits block (docs/store/HUMAN_CHECKLIST.md).

Format per entry: `path | origin | license | attribution | notes`.

## Added 2026-09-08 — residential district asset pass

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/tiles/residential_floor_lit.png` | AI-generated in-session (Arena image generation), reference = in-house `tiles/residential_floor.png` | Project-owned AI output; no third-party rights | none required | 256² RGB (downscaled 1024² LANCZOS), 80,160 B. Lit twin per docs/STYLE_GUIDE.md §4: same plank geometry, warm lift. Palette verified: min texel 11, max 84 (no pure #000/#fff). Edge-wrap seam delta 16.2 ≈ shipped dark twin 15.3. |
| `assets/textures/tiles/residential_wall_lit.png` | AI-generated in-session (Arena image generation), reference = in-house `tiles/residential_wall.png` | Project-owned AI output; no third-party rights | none required | 256² RGB (downscaled 1024² LANCZOS), 83,930 B. Same brick geometry, warm lift. Palette verified: min 33, max 157. Seam delta 4.6 ≈ shipped 4.5. |

Consumer (future wiring, CODE agent): `scripts/world/district_grading.gd::_apply_ground`
currently loads `tiles/<district>_floor.png`; the `_lit` twins follow the convention set by
`suburbs|hospital|power_station` `_lit` pairs for a stage-based ground swap.

## Added 2026-09-08 — park district asset pass

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/tiles/park_floor_lit.png` | AI-generated in-session (Arena image generation), reference = in-house `tiles/park_floor.png` | Project-owned AI output; no third-party rights | none required | 256² RGB (downscaled 1024² LANCZOS), 103,387 B. Warm lift per STYLE_GUIDE §4. Palette: min 11, max 147 (no pure #000/#fff). Seam delta 9.3 (shipped dark twin 4.4 — within house range, cf. residential pair 16.2/15.3). |
| `assets/textures/tiles/park_wall_lit.png` | AI-generated in-session (Arena image generation), reference = in-house `tiles/park_wall.png` | Project-owned AI output; no third-party rights | none required | 256² RGB (downscaled 1024² LANCZOS), 104,064 B. Palette-clamped (6..249). Seam delta 32.6 ≈ shipped dark twin 27.7. |
| `assets/textures/surfaces/pond_ice_512.png` | AI-generated in-session (Arena image generation), text-to-image, palette-locked prompt | Project-owned AI output; no third-party rights | none required | 512² RGB, 304,866 B (≤500 KB budget). Frozen pond for `z_pond` (park manifest gap #3). Dark steel-blue ice #131a20–#2a3340, pale cracks; min 9, max 127; seam 9.8. |

## Added 2026-09-08 — police district asset pass

Dark tiles `tiles/police_floor.png` / `police_wall.png` already ship; this pass adds the
missing `_lit` twins and one cell-bar prop face. No binary audio fabricated.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/tiles/police_floor_lit.png` | Derived in-session from in-house `tiles/police_floor.png` (luminance ×1.42 + brass warmth per STYLE_GUIDE §4/§4.1). An AI lit candidate was generated against the dark twin and discarded: geometry lock is the acceptance path. | Project-owned; no third-party rights | none required | 256² RGB, 80,067 B. Identical 4×4 tile grid. Measured: lift ×1.42 (target 1.35–1.50), geometry correlation 1.000, warmth R−B +25 (dark twin −19.5, target band +15…+40), palette 27..140, seam delta 5.1 vs dark 3.8 (ratio 1.34 — same class as school wall 4.4 vs 3.1). |
| `assets/textures/tiles/police_wall_lit.png` | Derived in-session from in-house `tiles/police_wall.png` (same method as the floor twin). | Project-owned; no third-party rights | none required | 256² RGB, 73,599 B. Same running-bond brick / mortar. Measured: lift ×1.42, geometry correlation 1.000, warmth R−B +25 (dark twin −18.8), palette 21..201, seam delta 4.9 vs dark 3.6. |
| `assets/textures/surfaces/cell_bars_512.png` | AI-generated in-session (Arena image generation), text-to-image, palette-locked prompt | Project-owned AI output; no third-party rights | none required | 512² RGB, 182,921 B (≤500 KB). Holding-cell bar face for `z_holding_cells`. Unlit night steel with brass `#c9a24a` bolt heads as the only accent; palette clamped 19..177 (no pure #000/#fff), warmth R−B −6 (cold body), mean luminance 41. Non-tiling panel class (seam metric N/A by class; measured 10.0). Deliberately textless — no cell numbers baked in. |

§4.1 numeric acceptance test applied to both lit twins (lift ratio, geometry correlation,
warmth band, palette clamp, seam delta) — lift/corr/warmth/palette inside the thresholds
in docs/STYLE_GUIDE.md; seam scales with the uniform lift (same observation as the school
wall pair).

## Added 2026-09-08 — gas_station district asset pass

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/tiles/gas_station_floor_lit.png` | AI-generated in-session (Arena image generation), reference image = in-house `tiles/gas_station_floor.png` | Project-owned AI output; no third-party rights | none required | 256² RGB (generated 1024², LANCZOS downscale), 107,047 B. Lit twin per STYLE_GUIDE §4/§4.1: same asphalt, same hazard-stripe band position, warm canopy lift only. Measured: lift ×1.42, geometry correlation 0.953, warmth R−B +30 (dark twin −0.6, target band +15…+40), palette 19..238, seam delta 5.3 vs dark 3.9. |
| `assets/textures/tiles/gas_station_wall_lit.png` | AI-generated in-session (Arena image generation), reference image = in-house `tiles/gas_station_wall.png` | Project-owned AI output; no third-party rights | none required | 256² RGB (generated 1024², LANCZOS downscale), 100,617 B. Same corrugated ribs and rust streak positions. Measured: lift ×1.42, geometry correlation 0.855 (≥0.85 threshold), warmth R−B +28 (dark twin −16.9), palette 56..217, seam delta 3.0 vs dark 4.2. Warmth was chroma-corrected after generation (the raw output came back at R−B +70, outside the §4.1 band). |
| `assets/textures/surfaces/fuel_pump_512.png` | AI-generated in-session (Arena image generation), reference image = in-house `surfaces/school_lockers_512.png` (style lock) | Project-owned AI output; no third-party rights | none required | 512² RGB, 267,351 B (≤500 KB). Petrol dispenser front for the six pumps in `z_pump_island`. Non-tiling panel class (seam metric N/A; measured 5.1). Mean luminance 72 — dead display, no lit digits, no brand text baked; single brass `#c9a24a` hose fitting as the only accent; palette clamped 19..200, warmth R−B −12 (cold body, warm fitting). |

§4.1 numeric acceptance test applied to both lit twins (lift ratio, geometry correlation,
warmth band, palette clamp, seam delta) — all within the thresholds recorded in
docs/STYLE_GUIDE.md, with the wall pair's warmth corrected post-generation.

## Added 2026-09-08 — hospital district asset pass

Note: hospital already ships both lit tile twins (`tiles/hospital_floor_lit.png`,
`tiles/hospital_wall_lit.png`) and both ambience beds, so this pass added **no** tiles and
**no** audio — only the three prop surfaces the manifest zones needed.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/surfaces/hospital_curtain_512.png` | AI-generated in-session (Arena image generation), reference image = in-house `tiles/hospital_wall.png` (style/palette lock) | Project-owned AI output; no third-party rights | none required | 512² RGB, 184,453 B (≤500 KB). Privacy-curtain fabric for `z_ward_b` beds. Mirror-tiled horizontally → **seam_h 0.0** (vertical wrap intentionally not seamless: a curtain hangs, top mesh band ≠ bottom hem, seam_v 29.6 is by design). Mean luminance 100 (shipped `hospital_wall.png` 95, `hospital_tile_dirty_512.png` 121), palette clamped 19..146, warmth R−B −16 (cold, STYLE_GUIDE §1). |
| `assets/textures/surfaces/morgue_drawers_512.png` | AI-generated in-session (Arena image generation), reference image = in-house `surfaces/school_lockers_512.png` (style lock) | Project-owned AI output; no third-party rights | none required | 512² RGB, 227,646 B. Drawer-bank wall for `z_morgue`. Mean luminance 100, palette 19..173, seam_h 4.3 / seam_v 9.1 (shipped `hospital_tile_dirty_512.png` 3.7), warmth R−B −15. Deliberately textless — no drawer numbers baked in. |
| `assets/textures/surfaces/xray_lightbox_512.png` | AI-generated in-session (Arena image generation), text-to-image, palette-locked prompt | Project-owned AI output; no third-party rights | none required | 512² RGB, 248,426 B. X-ray light box for `z_operating` / `z_records` (the `hospital_note_07` examine anchor). Non-tiling framed panel — seam metric N/A by class (measured 8.6/13.3, unused). Mean luminance 62 (dim, unlit-by-default), diffuser glass held at district accent teal `#5dc8f4`/`#4a9ab5` low energy, palette clamped 19..166 so nothing blows out; blank film sheet, no image, no text. |

Style compliance (STYLE_GUIDE §1–§3): all three read as unlit night props, matte, no pure
`#000`/`#fff`, no neon, no baked text/numbers, ≤512² and well under the 500 KB prop budget.
No lit-twin numeric test (§4.1) applies — no `_lit` variants were produced this pass.

## Added 2026-09-08 — school district asset pass

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/tiles/school_floor_lit.png` | AI-generated in-session (Arena image generation), reference image = in-house `tiles/school_floor.png` | Project-owned AI output; no third-party rights | none required | 256² RGB (generated 1024², LANCZOS downscale), 92,591 B. Lit twin per STYLE_GUIDE §4: identical 4×4 linoleum grid, warm lift only. Measured: luminance lift ×1.42 (target 1.35–1.5), geometry correlation vs dark twin 0.943 (shipped park pair 0.930), palette 33..138 (no pure #000/#fff), seam delta 3.4 vs dark twin 3.8, warmth R−B +24. |
| `assets/textures/tiles/school_wall_lit.png` | AI-generated in-session (Arena image generation), reference image = in-house `tiles/school_wall.png` | Project-owned AI output; no third-party rights | none required | 256² RGB (generated 1024², LANCZOS downscale), 93,566 B. Same locker-door geometry, vents/handles unmoved. Measured: lift ×1.42, geometry correlation 0.895, palette 19..239, seam delta 4.4 vs dark twin 3.1, warmth R−B +32. |
| `assets/textures/surfaces/school_lockers_512.png` | AI-generated in-session (Arena image generation), reference image = in-house `tiles/school_wall.png` (style lock) | Project-owned AI output; no third-party rights | none required | 512² RGB, 203,083 B (≤500 KB budget). Locker-door prop face for `z_corridor_lockers` 3D props (school prop_manifest gap #2). Unlit night steel #2a3340 with brass #c9a24a latches; palette 19..203, seam delta 2.3 after wrap blend, warmth R−B −17 (cold, per STYLE_GUIDE §1). |
| `assets/textures/surfaces/chalkboard_512.png` | AI-generated in-session (Arena image generation), text-to-image, palette-locked prompt | Project-owned AI output; no third-party rights | none required | 512² RGB, 313,689 B. Classroom chalkboard face for the `school_note_06` examine anchor (school prop_manifest gap #3). Deliberately textless (no letters/numbers) so the tally is drawn by CODE/UI, never baked into art; palette 19..208, seam delta 3.9, mean luminance 48. |

Consumers (future wiring, CODE agent): `_lit` tiles follow the
`suburbs|hospital|park|power_station|residential` convention for the stage-based ground swap
in `scripts/world/district_grading.gd::_apply_ground`; the two `surfaces/*` PNGs are prop
materials referenced by `content/districts/school/prop_manifest.md`.

## Pre-existing school binaries (provenance summary, unchanged)

All pre-existing school binaries (`tiles/school_floor.png`, `tiles/school_wall.png`,
`crests/crest_school_96.png`, `loading/school_loading.png`, `maps/school_map_512.png`,
`surfaces/school_floor_512.png`, `audio/ambience/districts/school_dark.ogg`,
`audio/ambience/district_details/school_{bell_echo,locker_slam,chalk_scratch,desk_scrape}.ogg`,
`audio/music/abandoned_hallways_alt.mp3`, retired to `_QUARANTINE/assets/audio/music/` in Session 27) were produced in-house by earlier sessions
(procedural generators / `tools/gen_audio.py`); project-owned, no attribution required.
Note: `assets/_orphaned/assets/textures/tiles/school_{floor,wall}_lit.png` are quarantined
artefacts of an earlier session and were **not** reused — the twins above were regenerated
against the shipped dark tiles, consistent with the residential and park passes.
No web-sourced assets are used in this district.

## Pre-existing residential binaries (provenance summary, unchanged)

All pre-existing binaries (`tiles/residential_*.png`, `crests/crest_residential_96.png`,
`loading/residential_loading.png`, `audio/music/residential.wav`,
`audio/ambience/districts/residential_dark.ogg`, `audio/ambience/district_details/residential_*.ogg`)
were generated in-house by earlier sessions (procedural generators / `tools/gen_audio.py`);
project-owned, no attribution required. No web-sourced assets are used in this district.

## Added 2026-09-09 — warehouses district asset pass

Dark tiles `tiles/warehouses_floor.png` / `warehouses_wall.png` already ship; this pass
adds the missing `_lit` twins and repairs an edge-frame defect found on the dark floor.
No binary audio fabricated.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/tiles/warehouses_floor.png` | Pre-existing in-house AI output (shipped dark tile); **edge-repaired in-session** | Project-owned; no third-party rights | none required | 256² RGB. Defect found by the §2 seam probe: an asymmetric 3 px dark frame on the top/left edges (mean Y 33 vs interior 45) gave a wrap seam of 18.8 — 4–5× the 3.8–4.4 house range (same probe on 7 shipped dark floors). Repair: the 3 frame rows/cols mirror-filled from interior rows/cols 5–3 across the boundary — 1,467 px of 65,536 (2.2%) changed, mean abs diff 0.32/255; wrap seam now **3.85** (in house range); palette unchanged 21..69; no other texel touched. |
| `assets/textures/tiles/warehouses_floor_lit.png` | Derived in-session from the (repaired) in-house dark tile — luminance ×1.42 + brass `#c9a24a` blend per STYLE_GUIDE §4/§4.1; AI-lit candidates not needed (geometry lock is the acceptance path, cf. police pass) | Project-owned; no third-party rights | none required | 256² RGB, 69,324 B. Concrete slab of the west/east shed floors. Measured: lift ×1.406 (target 1.35–1.50), geometry correlation 0.982 (≥0.85), warmth R−B +21.5 (dark twin −3.9; band +15…+40), palette 30..84 (no pure #000/#fff), wrap-blend 8 px seam 2.5 vs dark 3.8 (ratio 0.66 — wrap crossfade improves the seam; no seam regression). |
| `assets/textures/tiles/warehouses_wall_lit.png` | Derived in-session from in-house `tiles/warehouses_wall.png` (same method as the floor twin) | Project-owned; no third-party rights | none required | 256² RGB, 69,600 B. Corrugated steel wall, 32 px rib period preserved (measured horizontal period 32; ribs straight). Measured: lift ×1.417, geometry correlation 0.993, warmth R−B +21.3 (dark twin −15.9), palette 57..120, seam 2.6 vs dark 3.7 (ratio 0.70). |

§4.1 numeric acceptance applied to both lit twins (lift, geometry correlation, warmth
band, palette clamp, seam delta) — all inside the thresholds in docs/STYLE_GUIDE.md;
seam ratios below 1.0 because the 8 px wrap blend lands the lit twins *better* than
their dark sources (same observation class as the gas_station/police pairs, opposite
sign). Dark-twin repair is ledgered above because the lit twin is derived from the
repaired dark, keeping the pair geometry-locked (corr 0.982/0.993).

## Pre-existing warehouses binaries (provenance summary, unchanged except floor repair above)

All pre-existing binaries (`tiles/warehouses_floor.png`, `tiles/warehouses_wall.png`,
`crests/crest_warehouses_96.png`, `loading/warehouses_loading.png`,
`maps/warehouses_map_512.png`, `audio/ambience/districts/warehouses_dark.ogg`,
`audio/ambience/district_details/warehouses_{cargo_impact,chain_rattle,forklift_distant,metal_creak}.ogg`,
`audio/music/harbor.wav`) were produced in-house by earlier sessions (procedural
generators / `tools/gen_audio.py`); project-owned, no attribution required.
No web-sourced assets are used in this district.

## Added 2026-09-09 — industrial district asset pass

Dark tiles `tiles/industrial_floor.png` / `industrial_wall.png` already ship; this pass adds
the missing `_lit` twins. No dark-twin repair needed: the §2 seam probe (run first, warehouses
precedent) measured both dark twins clean — floor 3.81, wall 3.08, no edge-frame defect
(edge means match interior). No binary audio fabricated.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/tiles/industrial_floor_lit.png` | Derived in-session from in-house `tiles/industrial_floor.png` (luminance ×1.42 + brass `#c9a24a` blend per STYLE_GUIDE §4/§4.1). Two AI lit candidates were generated against the dark twin first and **discarded** (floor candidate lift ×2.29, wall corr 0.59 — the overshoot §4.1 predicts); geometry lock is the acceptance path (police/warehouses precedent). | Project-owned; no third-party rights | none required | 256² RGB, 65,410 B. Concrete slab factory floor. Measured: lift ×1.420 (target 1.35–1.50), geometry correlation 0.999 (≥0.85), warmth R−B +21.5 (dark twin −7.2; band +15…+40), palette 21..68 (no pure #000/#fff), wrap seam 2.12 vs dark 3.81 (ratio 0.56 — improvement-side, same class as the shipped warehouses pair 0.66; the brass pull toward a constant inherently shrinks edge deltas on a dark tile). Diff is a smooth uniform lift (per-pixel |Δ| 12.0–24.7, row/col profile std ≤2.0) — light only, no geometry repaint. |
| `assets/textures/tiles/industrial_wall_lit.png` | Derived in-session from in-house `tiles/industrial_wall.png` (same method as the floor twin). | Project-owned; no third-party rights | none required | 256² RGB, 71,254 B. Corrugated industrial siding. Measured: lift ×1.419, geometry correlation 0.998, warmth R−B +21.5 (dark twin −21.8), palette 68..163, wrap seam 2.62 vs dark 3.08 (**ratio 0.85 — inside the ±30% band**). Same smooth-lift profile (|Δ| 26.7–39.7, std ≤0.7). |

§4.1 numeric acceptance applied to both lit twins (lift, geometry correlation, warmth band,
palette clamp, seam delta) — lift/corr/warmth/palette all inside the thresholds in
docs/STYLE_GUIDE.md; seams land at or below their dark twins' (0.85 wall — in band; 0.56
floor — improvement-side deviation, documented above, no seam regression: both lit twins
wrap **better** than their dark sources, same observation class as the warehouses pass).
Both derive pointwise from the shipped dark tiles, so the pairs are geometry-locked by
construction (corr 0.998/0.999).

## Pre-existing industrial binaries (provenance summary, unchanged)

All pre-existing binaries (`tiles/industrial_floor.png`, `tiles/industrial_wall.png`,
`crests/crest_industrial_96.png`, `loading/industrial_loading.png`,
`maps/industrial_map_512.png`, `audio/ambience/districts/industrial_dark.ogg`,
`audio/ambience/district_details/industrial_{machinery_drone,pipe_hiss,steam_vent,vent_rattle}.ogg`,
`audio/music/industrial.wav`) were produced in-house by earlier sessions (procedural
generators / `tools/gen_audio.py`); project-owned, no attribution required. No web-sourced
assets are used in this district.

## Added 2026-09-09 — substation district asset pass

Dark tiles `tiles/substation_floor.png` / `substation_wall.png` already ship; this pass adds
the missing `_lit` twins. No dark-twin repair: the §2 seam probe (run first, warehouses
precedent) found the floor clean (4.35, no edge frame — edges match interior) and the wall
at 18.06 with NO frame defect either (top-3/left-3 rows match interior means) — the wall's
seam is intrinsic to its high-contrast speckle pattern (bright dots to 122 cut at the wrap
boundary), not a generation edge artifact, so the dark ships untouched (residential-floor
precedent: recorded outlier, not repaired). No binary audio fabricated.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/tiles/substation_floor_lit.png` | Derived in-session from in-house `tiles/substation_floor.png` (luminance ×1.42 + brass `#c9a24a` blend per STYLE_GUIDE §4/§4.1; warmth blend solved per tile to R−B +22, gas_station-wall precedent; geometry lock is the acceptance path, police/warehouses/industrial precedent — no AI candidates needed) | Project-owned; no third-party rights | none required | 256² RGB, 78,931 B. Diamond-mesh yard concrete. Measured: lift ×1.420 (target 1.35–1.50), geometry correlation 0.995 (≥0.85), warmth R−B +22.0 (dark twin +3.1; band +15…+40), palette 28..85 (no pure #000/#fff), wrap seam 1.14 vs dark 4.35 (ratio 0.26 — improvement-side, same class as the shipped industrial floor 0.56). Diff is a smooth uniform lift (per-pixel mean |Δ| 15.1, row/col profile std ≤0.13) — light only; 8 px border shows no luminance frame (border vs interior +0.02). |
| `assets/textures/tiles/substation_wall_lit.png` | Derived in-session from in-house `tiles/substation_wall.png` (same method as the floor twin) | Project-owned; no third-party rights | none required | 256² RGB, 86,755 B. Speckled concrete wall. Measured: lift ×1.420, geometry correlation 0.993, warmth R−B +22.0 (dark twin −6.6), palette 30..103, wrap seam 3.23 vs dark 18.06 (**ratio 0.18 — improvement-side; absolute 3.23 joins the 2.1–3.8 house range**). Same smooth-lift profile (mean |Δ| 17.4, std ≤0.59); no border frame (−0.01). |

§4.1 numeric acceptance applied to both lit twins (lift, geometry correlation, warmth
band, palette clamp, seam delta) — lift/corr/warmth/palette all inside the thresholds in
docs/STYLE_GUIDE.md; seams land below their dark twins' (0.26 floor, 0.18 wall —
improvement-side deviations, documented above, no seam regression: both lit twins wrap
**better** than their dark sources, same observation class as the warehouses/industrial
passes; the wall's larger ratio is an arithmetic consequence of its dark twin being a
recorded 18.06 outlier, and its absolute 3.23 matches the shipped family). Both derive
pointwise from the shipped dark tiles, so the pairs are geometry-locked by construction
(corr 0.993/0.995).

## Pre-existing substation binaries (provenance summary, unchanged)

All pre-existing binaries (`tiles/substation_floor.png`, `tiles/substation_wall.png`,
`crests/crest_substation_96.png`, `loading/substation_loading.png`,
`maps/substation_map_512.png`, `audio/ambience/districts/substation_dark.ogg`,
`audio/ambience/district_details/substation_{transformer_buzz,arc_crackle,cable_hum}.ogg`,
`audio/music/music_ambient_dark.wav`, retired to `_QUARANTINE/assets/audio/music/` in Session 27) were produced in-house by earlier sessions
(procedural generators / `tools/gen_audio.py`); project-owned, no attribution required.
No web-sourced assets are used in this district.

## Added 2026-09-09 — power_station district asset pass

**No new binaries.** Both lit twins ship pre-existing (predating the §4.1 test, which was
added with the school pass), and the crest / loading art / map all ship — "generate only
missing pieces" yields an empty set (YAGNI). This pass re-measures the shipped pairs for
the record instead of churning them (residential/hospital precedent: re-deriving a shipped
pair is a texture pass on its own).

Re-measured 2026-09-09 (Pillow + numpy, same §4.1 metrics):

| Pair | Lift (1.35–1.50) | Corr (≥0.85) | Warmth (+15…+40) | Palette | Seam lit/dark |
|---|---|---|---|---|---|
| `power_station_floor` → `_lit` | **×1.561 (above band)** | 1.000 | **+4.7 (below band; dark −6.2)** | 32..233 | 18.42 / 15.88 (ratio 1.16, in band) |
| `power_station_wall` → `_lit` | ×1.415 | 0.999 | **+12.1 (just below band; dark −8.2)** | 46..121 | 3.64 / 3.08 (ratio 1.18, in band) |

Reading: the floor lit twin is brighter-but-not-warmer (lift overshoot, warmth undershoot
— the exact AI-overshoot shape §4.1 predicts, shipped before the test existed); the wall
twin meets every band except warmth, which it misses by 3 points. Both pairs are
geometry-locked (corr ≥0.999) and both seams sit in-band. The floor dark's own 15.88 seam
joins the recorded outlier class (residential floor 15.3, substation wall 18.06 —
intrinsic pattern contrast, no frame defect, deliberately unrepaired). Council decision
(skill `council`, logged): leave the shipped pair untouched — the game already renders it,
no defect breaks loading, and §4.1 gates new twins, not shipped history.

## Pre-existing power_station binaries (provenance summary, unchanged)

All pre-existing binaries (`tiles/power_station_floor.png`,
`tiles/power_station_floor_lit.png`, `tiles/power_station_wall.png`,
`tiles/power_station_wall_lit.png`, `crests/crest_power_station_96.png`,
`loading/power_station_loading.png`, `maps/power_station_map_512.png`,
`audio/ambience/districts/power_station_dark.ogg`,
`audio/ambience/districts/power_station_lit.ogg`,
`audio/ambience/district_details/power_station_{generator_thrum,hv_whine,cooling_fan,breaker_clunk}.ogg`,
`audio/music/music_ambient_dark.wav`, retired to `_QUARANTINE/assets/audio/music/` in Session 27) were produced in-house by earlier sessions
(procedural generators / `tools/gen_audio.py`); project-owned, no attribution required.
No web-sourced assets are used in this district.

## Added 2026-09-09 — finishing pass: CC0 audio sourcing attempts (Task 2)

**No binaries added.** Task 2 asked to close the `docs/AUDIO_COVERAGE.md` audio gaps (lit beds
G1, G2b/c/e/f/g/h/i; F1 detail class; optional flavor items) with real CC0/CC-BY tracks, and,
where none is suitable, to keep the spec and record the search attempt honestly. Web searches
were run for every gap class on 2026-09-09 (queries targeted CC0/CC-BY ambience, room tone,
industrial/generator hum, hospital ward, school corridor, gas-station/streetlight-night
ambience, seamless loop). Outcome for **all** gaps: **spec retained, no source adopted.** Reasons
recorded honestly:

1. **Contract mismatch (decisive).** Every lit bed is defined in `docs/AUDIO_COVERAGE.md` as a
   *faithful "lit twin" re-voice of that district's own synthesized dark bed* (STYLE_GUIDE §5) —
   exact 36.000 s seamless loop (33.994 s for industrial to match its shipped dark), −18 LUFS,
   district-true material, plus per-bed "never wallpaper the anomaly / never include voices"
   rules. No CC0/CC-BY source is a re-voice of an in-repo synthesized file; none matches the
   exact loop lengths, and many candidates (ZapSplat hospital/school ambience) contain exactly
   the voices/people those specs forbid.
2. **License (secondary).** The richest ambience/room-tone candidates (ZapSplat, several
   hospitals/school/industrial hums) are **Standard License, not CC0/CC-BY** — outside the repo's
   only-permitted origins. Genuine CC0 libraries (freesound CC0 sets, e.g. `PtrMan`'s public CC0
   list, `signaturesounds.org` CC0 ambience packs) contain generic drones/room tones only, none
   district-true.
3. **Delivery toolchain absent in sandbox.** No `ffmpeg`/`ffprobe` (verified), so no candidate
   could be re-normalized to −18 LUFS / TP ≤ −1.5 dBFS, re-encoded to OGG q4 mono, or verified —
   per pipeline rule every delivered binary must be header- and loudness-verified before commit.
   A downloaded binary delivered un-verified would violate `docs/AUDIO_LOUDNESS.md`.

F1 (power_station `generator_thrum` 28.749 s, `cooling_fan` 28.948 s vs the 30 s detail class)
is recorded in `docs/AUDIO_COVERAGE.md` as a **finding, not a gap** — both files exist, loop via
`AudioStreamOggVorbis.loop=true`, and play correctly; re-render at 30.000 s is the audio
toolchain holder's call, and a generic CC0 "generator hum" is not a substitute for the district
detail. No binary audio has been fabricated at any point by this pipeline.

## Added 2026-09-09 — Play Store kit art (Task 3, store/**)

Store key art generated in-session (Arena image generation), text-to-image, palette-locked per
docs/STYLE_GUIDE.md §2/§6. Post-processed deterministically (ImageMagick): pure-black/white
clamped to `#0a0d12` / `#f0ead9`, exact store dimensions enforced, title composited in bone
`#f2ecd9` + brass `#c9a24a` (DejaVu-Sans-Bold) over a dark gradient band — no baked-text glyph
risk. Store art is a distinct class from in-game textures (asset_pipeline: "skip grain on store
art"); no pure `#000`/`#fff` texels remain (verified 0).

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `store/feature-graphic.png` | AI-generated in-session (Arena image generation), palette-locked | Project-owned AI output; no third-party rights | none required | 1024×500 sRGB. Permanent-night city, one brass streetlamp cone; title overlay. Palette-clamped, 684,630 B. |
| `store/icon-512.png` | AI-generated in-session (Arena image generation), palette-locked | Project-owned AI output; no third-party rights | none required | 512×512 sRGB. Streetlamp-head crest emblem on night sky. Palette-clamped, 300,965 B. |

## Added 2026-09-10 — mega final pass: audio gap re-attempt (Task 1)

**No binaries added.** The mega final pass re-opened every `docs/AUDIO_COVERAGE.md` gap
(lit beds G1, G2b/c/e/f/g/h/i; F1 detail class; optionals G2/G4/G5 and
`hospital_ward_curtain_drag.ogg`) under the Task 1 ladder: (a) audio-generation skill →
(b) CC0/CC-BY exact-match → (c) spec-only with an honest record.

(a) **No audio-generation skill exists in this session.** Skill discovery at pass start:
`.opencode/skills/` holds `yagni, self-commit, godot-gates, surgical-edit, council,
art-pipeline` (all code/process/texture skills — none synthesizes audio);
`docs/external_skills/` holds only `karpathy-behavior.md` (LLM behavior, no tools);
`docs/superpowers/specs/` holds a release-defect design doc (no tools). The sandbox
toolset offers spoken-word TTS only, which by definition outputs *voices* (every lit-bed
spec forbids voices/people) and cannot render a 36.000 s seamless instrumental loop to a
−18 LUFS / TP ≤ −1.5 dBFS contract. Step (a) is therefore impossible here, not skipped.

(b) **CC0/CC-BY exact-match search re-run 2026-09-10 — no source adopted.** Queries:
CC0 seamless ambient loops; CC-BY school-corridor night ambience; freesound CC0
industrial night hum; CC0 warm pad/drone loop beds. Genuine CC0 material exists but none
is an exact match: `signaturesounds.org` CC0 ambient-loops pack (90 generic
loops/textures, none district-true, none a re-voice of an in-repo dark bed);
`selektaudio.com` CC0 drones (`ambience04` 40.5 s, `eerie:despair` 2:44 — wrong lengths,
generic material); freesound `IanStarGem` Industrial/Factory Fans CC0 (**43.878 s stereo**,
6.7 s loop variant — wrong length, stereo not mono, not a re-voice of
`industrial_dark.ogg`); PtrMan CC0 list (generic pads/drones/room tones only);
Envato/123RF school-corridor hits (royalty-free/Standard, **not** CC0/CC-BY).
Decisive blockers, same as the 2026-09-09 pass: every lit bed is defined as a faithful
re-voice of its district's own synthesized dark bed at an exact loop length with
per-bed never-rules — no third-party file can satisfy that; and no `ffmpeg`/`ffprobe`/
encoder exists in this sandbox (verified absent), so no candidate could be
re-normalized to −18 LUFS, re-encoded OGG q4 mono, or loudness-verified before commit.

(c) **All gaps remain spec-only — no binary fabricated.** Static re-verification this
pass (Ogg/Vorbis header + final-page granule parse, no engine): all 11 dark beds and
all 3 shipped lit beds measure exactly as recorded (36.000 s mono 44.1 kHz; industrial
dark 33.994 s per G2h; F1 pair still 28.749/28.948 s, finding not gap); all other 38
detail beds exactly 30.000 s. Zero drift since 2026-09-09.

## Added 2026-09-10 — mega final pass: trailer graphics (Task 2, store/trailer/**)

Trailer/viral-shorts art generated in-session (Arena image generation), text-to-image,
palette-locked per docs/STYLE_GUIDE.md §2/§6. Post-processed deterministically (Pillow):
center-crop to exact size, pure-black/white clamped to `#0a0d12` / `#f0ead9` (verified 0
pure texels in all 5 files), press-kit title/tagline composited in bone `#f2ecd9` + brass
`#c9a24a` (DejaVu-Sans-Bold) — no baked-AI-text glyph risk. Store/trailer art is a
distinct class from in-game textures (asset_pipeline: "skip grain on store art").

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `store/trailer/still_first_light_1920x1080.png` | AI-generated in-session, palette-locked | Project-owned AI output; no third-party rights | none required | 1920×1080 sRGB. First streetlight restore wow-moment; no HUD. |
| `store/trailer/still_first_ending_1920x1080.png` | AI-generated in-session, palette-locked | Project-owned AI output; no third-party rights | none required | 1920×1080 sRGB. Half-lit city ending tease; spoiler-safe. |
| `store/trailer/still_grid_cascade_1920x1080.png` | AI-generated in-session, palette-locked | Project-owned AI output; no third-party rights | none required | 1920×1080 sRGB. Grid-cascade wave; Shorts cover frame. |
| `store/trailer/shorts_silhouette_1080x1920.png` | AI-generated in-session, palette-locked | Project-owned AI output; no third-party rights | none required | 1080×1920 sRGB. Vertical silhouette vs lit skyline. |
| `store/trailer/presskit_1600x900.png` | AI-generated bg + PIL-composited title/tagline + 3 shipped district loading thumbs (×2.2 legibility lift, press-kit only) | Project-owned AI output + in-house art; no third-party rights | none required | 1600×900 sRGB. Press-kit header. |

## Added 2026-09-10 — GOLD MASTER v2: Android adaptive-icon layers (store/icon-adaptive/**)

Derived deterministically from `store/icon-512.png` by
`tools/gen_adaptive_icon.py` (re-run on any 512-master change). No new
source art: the shipped crest resampled into the inner 66% safe zone,
per-channel values clamped to `[16,216]` (~`#101418`..`#d8d2c4`), paired
with a flat `#141b24` (STYLE_GUIDE "panel") opaque background. Verified:
both 1080×1080; foreground RGBA transparent field, opaque region extrema
in range, content inside the safe zone; background fully opaque, extrema
in range; 0 pure `#000`/`#fff` texels (`gen_adaptive_icon.py --check`).

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `store/icon-adaptive/foreground_1080x1080.png` | Derived from `store/icon-512.png` (in-house master), Pillow, deterministic | Project-owned; no third-party rights | none required | 1080×1080 RGBA. Adaptive-icon foreground, crest in 66% safe zone on transparent field, clamped palette. |
| `store/icon-adaptive/background_1080x1080.png` | Generated flat colour, Pillow | Project-owned; no third-party rights | none required | 1080×1080 RGBA opaque. Adaptive-icon background, flat `#141b24`. |

## Audit checklist (run each asset pass)

1. `git diff --stat` binaries vs. this ledger — every row present.
2. Web-sourced rows: license text archived in `docs/reference/` + credit line present.
3. Sizes within budget (PRODUCTION_BIBLE §4): tiles ≤256² / ~500 KB.
4. No pure #000/#fff texels in UI-visible art (STYLE_GUIDE §2).

## Added 2026-09-10 — final audio pass: lit-bed generation attempt (Task 1)

**No binaries added; ledger unchanged.** Task 1 of the final audio pass asked to close the
eight remaining lit-bed gaps in `docs/AUDIO_COVERAGE.md` (G1 `residential_lit`; G2b
`park_lit`; G2c `school_lit`; G2e `gas_station_lit`; G2f `police_lit`; G2g `warehouses_lit`;
G2h `industrial_lit`; G2i `substation_lit`; F1 class re-checked) via music-generation skills
(Suno/Udio-class, exact house contract), and — where generation is unavailable or fails the
contract — to keep the spec and record the attempt honestly.

(a) **No music-generation capability exists in this session.** Skill discovery at pass start:
`.claude/skills/` (ponytail×6 — coding discipline), `.opencode/skills/` (`art-pipeline`,
`council`, `godot-gates`, `self-commit`, `surgical-edit`, `yagni`), `.pi/skills/`
(`gdd-canon`, `godot-gates`, `self-commit`, `surgical-edit`), `docs/external_skills/`
(`karpathy-behavior.md`) — none synthesizes audio. Repo-wide search for Suno/Udio/MusicGen
yields prose mentions only; no tool binding or credentials. The sandbox's sole audio tool is
spoken-word TTS, which cannot render melodic/seamless instrumental loops and would output
voices every lit-bed spec forbids. **Contract-true generation was attempted to the limit of
discovery and is impossible here — recorded, not skipped.**

(b) **Briefs deposited for the toolchain holder.** Per-gap music-generation prompts (dark-bed
mood/tempo/instrumentation + district-true brighter/warmer modifier + exact contract) are now
recorded in `docs/AUDIO_COVERAGE.md` §"Final-audio-pass note" step (b), ready to paste into
Suno/Udio by the first session/owner holding such a tool. On receipt: Ogg/WAV header-verify +
`ffmpeg loudnorm` to −18 LUFS / TP ≤ −1.5 dBFS (docs/AUDIO_LOUDNESS.md), house naming
(`<district>_lit.ogg`), and a ledger row here with full origin/license/attribution. The CC0/
CC-BY sourcing alternative remains exhausted per the 2026-09-09 finishing pass and the
2026-09-10 mega final pass records above (not re-run a third time).

(c) **Honest spec retention delivered.** No audio was fabricated and no metadata invented:
the sandbox has no Vorbis encoder and no `ffmpeg`/`ffprobe` (verified absent this session),
so no deliverable could meet the pipeline's verify-before-commit rule. Static re-verification
this pass (stdlib Ogg/Vorbis header + final-page granule parse; no engine): all 14 shipped
beds read 1 ch / 44,100 Hz / 36.000 s (`industrial_dark` 33.994 s per G2h) — byte-identical
durations and sizes to the 2026-09-09/10 records; all 8 lit files confirmed absent; F1 pair
(28.749/28.948 s) unchanged, finding not gap. Lit beds delivered: **3/11 shipped** (suburbs,
hospital, power_station) + **0/8 new** this pass.

## Added 2026-09-11 — GOLD MASTER v4: mobile-art pass (touch HUD + onboarding, Path B recreate)

`arena/01a08c53-igra` existed but carried **zero new commits** (tip = `540c57a`, already an
ancestor of `main` — no payload landed), so this pass was recreated deterministically:
`tools/gen_mobile_art_pass.py` (`--check` gate), Pillow only, no randomness, STYLE_GUIDE §2
palette. Touch glyphs: RGB clamped `[12,216]` wherever alpha > 0, alpha capped at 226 (stay
semi-transparent over the world), 0 pure `#000`/`#fff`, all ≤30 KB (largest is 2.0 KB).
Onboard stills: same "flat silhouettes on bg-deep, one warm light source max" class as the
shipped `onboard_01..04` (STYLE_GUIDE "Loading art" row), RGB clamped `[12,216]`.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/touch/touch_joy_base_256.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 256×256 RGBA. Virtual-joystick ring, semi-transparent. |
| `assets/textures/touch/touch_joy_knob_256.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 256×256 RGBA. Virtual-joystick knob. |
| `assets/textures/touch/touch_interact_128.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 128×128 RGBA. Lantern-in-hand interact glyph (available skin; current `BtnInteract` keeps its shipped SVG icon — see `docs/ASSET_HANDOFF.md`). |
| `assets/textures/touch/touch_pause_128.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 128×128 RGBA. Pause glyph (available skin). |
| `assets/textures/touch/touch_back_128.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 128×128 RGBA. Back-chevron glyph — wired into the new Help/Codex screen. |
| `assets/textures/touch/help_controls_96.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 96×96 RGBA. D-pad glyph, Help/Codex controls section. |
| `assets/textures/touch/help_battery_96.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 96×96 RGBA. Battery glyph, Help/Codex. |
| `assets/textures/touch/help_puzzle_96.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 96×96 RGBA. Plug/socket glyph, Help/Codex. |
| `assets/textures/touch/help_stealth_96.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 96×96 RGBA. Crossed-eye glyph, Help/Codex. |
| `assets/textures/onboard_v2/onboard_05_light_cone_1024x576.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 1024×576 RGB. Flashlight+battery onboarding beat. |
| `assets/textures/onboard_v2/onboard_06_cable_box_1024x576.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 1024×576 RGB. Cable-puzzle onboarding beat. |
| `assets/textures/onboard_v2/onboard_07_crouch_hunter_1024x576.png` | Generated (Pillow, deterministic) | Project-owned; no third-party rights | none required | 1024×576 RGB. Stealth (crouch vs. hunter cone) onboarding beat. |

## Added 2026-09-12 — VISUAL asset pass (11 LUTs, 8 screenshots, 4 trailer re-grades)

Delivered via `arena/01a0902d-igra`, merged `1382035`. Full pipeline/verification narrative
consolidated from `docs/LEDGER_VISUAL.md` (kept on disk, indexed in `docs/RELEASE_ARTIFACTS.md`).
Every item is deterministic numpy/PIL transform output or Arena AI image generation composited
with repo-owned art — project-owned, no third-party rights.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/luts/lut_<district>.png` (11 files) | Generated (numpy/PIL, deterministic) | Project-owned; no third-party rights | none required | 256×16 Godot `Environment.color_correction` LUTs, per-district tint sourced from `district_themes.gd` THEMES. 0 row-monotonicity defects; twin districts byte-identical. |
| `store/screenshots/shot{01,02,05,07,08}_*_1920x1080_en.png` (5 files) | Arena AI image gen (env frames) + programmatic post (LUT luma-mix 0.6, bloom, vignette) | Project-owned AI output; no third-party rights | none required | Palette-clamped [16,240], mean saturation ≤40. Shot 8 is a programmatic composite of the repo's own city-overview map + district crests, no AI text. |
| `store/screenshots/shot_p{1,2,3}_touch_*_1920x1080_en.png` (3 files) | Composite of repo touch-HUD sprites + programmatic HP/stamina/battery bars | Project-owned; no third-party rights | none required | 20:9 content centered + letterboxed in 1920×1080, flat `#0c1016` bars (pixel-exact). |
| `store/trailer/still_first_light/_first_ending/_grid_cascade/shorts_silhouette` (4 files, re-graded in place) | Existing Arena AI stills, re-graded | Project-owned; no third-party rights | none required | Per-district LUT luma-mix (0.55), re-clamped [10,240]. Originals recoverable from git history. `presskit_1600x900.png` deliberately left ungraded (3-district composite). |

## Added 2026-09-12 — AUDIO asset pass (8 lit ambience beds + 3 wow cues)

Delivered via `arena/01a0902d-igra`, merged `1382035`. Full pipeline/verification narrative
consolidated from `docs/LEDGER_AUDIO.md`. Pure synthesis (numpy) + `ffmpeg loudnorm`/encode —
zero third-party samples, zero voices (auditable in the committed generator script).

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/audio/ambience/districts/{gas_station,industrial,park,police,residential,school,substation,warehouses}_lit.ogg` (8 files) | Generated (numpy synth + `ffmpeg loudnorm`, deterministic, seeds 1101-1108) | Project-owned; no third-party rights | none required | Fills gaps G1, G2b/c/e/f/g/h/i in `docs/AUDIO_COVERAGE.md`. 36.000s exact (G2h twin 33.994s), -18 LUFS, OGG q4 mono 44.1k. |
| `assets/audio/music/cue_{first_light,grid_cascade,victory}.ogg` (3 files) | Generated (numpy synth + `ffmpeg loudnorm`, seeds 1201-1203) | Project-owned; no third-party rights | none required | Wow-moment one-shot cues, 60/90/120s, arc-verified by 8th-window RMS decode. |
| `assets/audio/_build/gen_audio_pass.py` | Repo-owned tool | Project-owned | none required | Deterministic renderer for the two rows above; import-excluded via `.gdignore`. |

## Added 2026-09-13 — AUDIO/VISUAL FINALE pass (postfx presets + trailer heroes)

Delivered via `arena/01a09712-igra`, merged `36c3673`. Full attempt log consolidated from
`docs/LEDGER_FINALE.md` §F-LIC (drafted there since that pass is not this file's owner).

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/postfx/presets.json`, `assets/textures/postfx/README.md` | Project-authored preset data | Project-owned; no third-party rights | none required | 11-district bloom/vignette/chroma/grain data; wired live in `scripts/world_env_setup.gd` (bloom) and `scripts/post_process_overlay.gd` (vignette/chroma/grain). |
| `store/trailer/hero_{first_restore,grid_cascade,reactor_room}_1920x1080.png`, `hero_shorts_cut_1080x1920.png` (4 files) | AI-generated (in-session image generation, finished with project LUTs/shaders per `store/trailer/README.md`) | Project-owned; no third-party rights | none required | Marketing masters only, never runtime textures (3.5-4.0 MB each, full postfx stack baked in). |

## Added 2026-09-14 — 7 unique district card art pass (generated, graded, shipped)

Closes the shared-photo defect (`docs/KNOWN_ISSUES.md`): park, school,
hospital, gas_station, police, warehouses and substation were generated
in-session from text prompts (`docs/CARD_ART_BRIEF.md` §4, best candidate
per district), 2:3 center-cropped → 1024×1536, and graded by
`scripts/regen_cards_v2.py` (histogram-match to the district keeper +
saturation rolloff + palette lock + clamp [16,240] + seeded grain) with
all 8 validation checks PASS per district. The 512² twins are
byte-identical to the shipped unlocked textures. Locked variants are
derived from the twins by `scripts/make_locked_cards.py` (deterministic
per-pixel RGB affine OLS-fit on the 4 keeper pairs + flat accent×0.6
border + seeded grain 0.01; two full runs byte-identical). The 1024×1536
masters exceed the 500 KB texture budget by design: they are content
masters in `content/cards/`, not engine textures, and must stay the
canonical lossless pipeline output (byte-reproducible determinism).

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `content/cards/district_<d>.png` (7 files: gas_station 3,407,561 B; hospital 3,421,078; park 3,439,636; police 3,470,566; school 3,394,371; substation 3,454,858; warehouses 3,469,336) | AI-generated in-session (Arena image generation), text-to-image from `docs/CARD_ART_BRIEF.md` §4 prompts, no reference photo; graded deterministically by `scripts/regen_cards_v2.py` | Project-owned AI output; no third-party rights | none required | 1024×1536 masters, 8/8 checks PASS per district (per-image report in the `feat(art): generate + grade 7 unique district cards` commit). |
| `content/cards/twins/card_<d>_512.png` (7 files, 468,981–515,651 B) | Derived in-session from the masters above (`scripts/regen_cards_v2.py --emit-512`: 512² + 4px accent border) | Project-owned AI output; no third-party rights | none required | Byte-identical to the shipped unlocked textures below. |
| `assets/textures/cards/card_<d>_512.png` (7 files, same sizes as the twins) | Byte-copies of `content/cards/twins/card_<d>_512.png` | Project-owned AI output; no third-party rights | none required | Replace the seven shared-photo textures. Loaded by name from `scripts/ui/collection_ui.gd` (no code change). Palette 16–240, no pure #000/#fff. |
| `assets/textures/cards/card_<d>_locked_512.png` (7 files: gas_station 355,039 B; hospital 361,029; park 363,892; police 381,213; school 351,235; substation 372,909; warehouses 373,858) | Derived in-session from the in-house unlocked twins (`scripts/make_locked_cards.py`; "darkened desaturated fog" per `docs/LEDGER_ARTFINAL.md` L93) | Project-owned; no third-party rights | none required | 512², palette 16–146 (no pure #000/#fff), flat accent×0.6 border (keeper locked borders measured flat, std 0.0). Scene structure preserved (per-channel interior std 9–17 ≈ keeper locked 10–15). |
| `docs/artifacts/art-final/cards_contact_sheet.png` (2,193,453 B) | Derived in-session (`scripts/make_card_contact_sheet.py`: 4×6 grid of 256² LANCZOS thumbnails of the 22 shipped cards, order recovered by cell-matching the pre-replacement sheet) | Project-owned; no third-party rights | none required | 1024×1536. |

## Added 2026-10-17 — Session 27 M1: the generated music (12 files)

Origin of all 12: the Music skill of the Gemini app (gemini.google.com, Lyria, SynthID-watermarked by Google) on the owner's Google account (Google AI Pro), model selector 3.5 Flash-Lite (the Argon model answers that the Music skill is not enabled for it; the owner agreed to Flash-Lite for the generation and the selector was set back to Argon, High, after the last take). Each take is a 192 kbps MP3 of 90 to 180 s downloaded with the page's own download menu (audio only); the raw takes are kept outside the tree in `..\_BACKUPS\2026-10-17_music_raw`. Each file is `python tools/qa_sim/music_post.py <take> <target> --loop <s>` (the steadiest stretch of the take, an equal-power crossfade of the tail into the head, mono 44.1 kHz, one measured gain to -18 LUFS with the true peak limited to the law, OGG q4, measured after the write); `python tools/qa_sim/music_post.py --demo` is its check and `docs/artifacts/rc16/proofs/s27_m1_cb55efd.music_post.out` the raw output of the 12 runs rebuilt from the takes (the decoded audio of each is the same as the committed file's).

Licence position (AF6): Google's Terms of Service say Google will not claim ownership of content a user creates with its services (policies.google.com/terms, "Content in Google services", read 2026-10-17); they also bar using generated content to develop machine-learning models and presenting generated content as human-made. Neither the Terms, nor the generative-AI terms page (policies.google.com/terms/generative-ai), nor the Lyria 3 launch post (blog.google, read 2026-10-17) has a sentence on commercial use of music made in the Gemini app. **Commercial rights are UNVERIFIABLE-HERE; owner action (step 1 of `docs/RESUME_NOTE.md`): read the Gemini Apps terms of the account and accept them or replace the files** (`docs/GEMINI_HANDOFF.md` lists the targets and prompts). The eight synthesized lit beds these files replace stay on disk, so pointing the eight entries of `AMBIENCE_LIT_BY_DISTRICT` back is the whole switch for them. The credits screen says the music is AI-generated (`CREDITS_MUSIC`, 13 locales) and the store text says so too, because the Terms bar presenting generated content as human-made.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/audio/music/music_menu_dark.ogg` (1,027,524 B) | Gemini app Music skill on 2026-10-16, chat `ccccd89168f57db8`, prompt `Instrumental dark ambient nocturne, 66 BPM, D minor, 4/4. A lonely felt piano plays a sparse six-note hook over a warm analog pad and a deep sub drone; soft tape hiss and distant night-city air. Melancholic, suspended, solitary, nocturnal, quietly hopeful. Cold darkness with one warm brass-lit glow. No vocals, no drums, seamless loop.`; take `gem_menu_dark/clip.mp3` of 176.6 s; stretch from 26.0 s, loop 120.000 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.10 LUFS, true peak -1.90 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/suburbs.ogg` (334,197 B) | Gemini app Music skill on 2026-10-16, chat `0257970664d46631`, prompt `Instrumental ambient theme, 90 BPM, C pentatonic, 4/4. Gentle generative pad arpeggio like a music box remembered from childhood, warm tone over a cold low drone. Wistful, homespun, muted, open, unguarded. Night suburb with one amber streetlight. No vocals, no drums, seamless loop.`; take `gem_suburbs/clip.mp3` of 178.7 s; stretch from 56.0 s, loop 37.333 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.00 LUFS, true peak -3.50 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/school.ogg` (289,673 B) | Gemini app Music skill on 2026-10-16, chat `23aaac22060ed2ee`, prompt `Instrumental ambient theme, 100 BPM, E minor-major ambiguity, 4/4, long hall reverb. Glassy pad ostinato like a distant music classroom, cold institutional air. Fluorescent, nostalgic-broken, austere, echoey, cold. No vocals, no percussion, seamless loop.`; take `gem_school/clip.mp3` of 142.9 s; stretch from 92.5 s, loop 33.600 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.10 LUFS, true peak -2.60 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/hospital.ogg` (319,159 B) | Gemini app Music skill on 2026-10-16, chat `ef4c54603cb3432d`, prompt `Instrumental ambient theme, 60 BPM, whole-tone scale on F#, 4/4. Weightless floating pads that never resolve, clinical hum, faint monitor blip. Adrift, calm-sick, antiseptic, hollow, wrong. A hospital that must never feel like home. No vocals, no percussion, seamless loop.`; take `gem_hospital/clip.mp3` of 116.2 s; stretch from 32.0 s, loop 40.000 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.00 LUFS, true peak -2.10 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/gas_station.ogg` (306,420 B) | Gemini app Music skill on 2026-10-16, chat `901a7548b53a5376`, prompt `Instrumental ambient theme, 110 BPM, E blues, 4/4. Muted bluesy pad licks over an electrical hum, idle forecourt energy, ember-lit darkness. Roadside, restless, oily, electric, lonely. No vocals, no drums, seamless loop.`; take `gem_gas_station/clip.mp3` of 160.5 s; stretch from 44.5 s, loop 34.909 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.00 LUFS, true peak -2.00 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/police.ogg` (231,253 B) | Gemini app Music skill on 2026-10-17, chat `abf059d280f79828`, prompt `Instrumental ambient theme, 120 BPM, F minor, 4/4. Terse staccato pads and a quiet ticking pulse, indigo-cold authority, surveillance stillness. Procedural, restrained, hard, grim, airless. No vocals, no drums, seamless loop.`; take `gem_police/clip.mp3` of 176.7 s; stretch from 6.0 s, loop 28.000 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.00 LUFS, true peak -2.70 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/warehouses.ogg` (336,985 B) | Gemini app Music skill on 2026-10-17, chat `8beb1a02cacd170e`, prompt `Instrumental ambient theme, 75 BPM, C dorian, 4/4. Low drifting dorian pads with distant chain-clank ghosts in cavernous reverb, fog-softened edges. Cavernous, patient, foggy, metallic, minor-hopeful. No vocals, no drums, seamless loop.` (the first send failed with "I encountered an issue generating the track", chat `725cc43000640742`, and was sent again); take `gem_warehouses/clip.mp3` of 161.3 s; stretch from 35.0 s, loop 38.400 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.00 LUFS, true peak -2.80 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/substation.ogg` (293,410 B) | Gemini app Music skill on 2026-10-17, chat `1f4d5ee9ab7b8535`, prompt `Instrumental ambient theme, 100 BPM, D phrygian dominant, 4/4. Nervous ostinato under a high voltage whine, arc-crackle texture, pale desaturated air. Energized, alien, crackling, cold, watchful. No vocals, no drums, seamless loop.`; take `gem_substation/clip.mp3` of 160.3 s; stretch from 109.0 s, loop 33.600 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.00 LUFS, true peak -2.10 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/power_station.ogg` (293,084 B) | Gemini app Music skill on 2026-10-17, chat `277834d2d7cb8ced`, prompt `Instrumental ambient theme, 105 BPM, G mixolydian, 4/4. Broad resolute pads over a monumental generator thrum, the city's dead heart still charged. Charged, humming, finale-facing, monumental, resolute. No vocals, no drums, seamless loop.`; take `gem_power_station/clip.mp3` of 174.4 s; stretch from 75.0 s, loop 32.000 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.00 LUFS, true peak -2.50 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/music_boss_dark_p1.ogg` (350,425 B) | Gemini app Music skill on 2026-10-17, chat `cec5614a253e02e5`, prompt `Instrumental boss tension loop, 80 BPM, D minor, 4/4, seamless 45-second loop. Low sustained cello-like drone, muted heartbeat pulse, airy noise swells, no melody. Coiled, patient, predatory, subterranean, clinical. The thing in the dark has noticed you. No vocals, no drums.`; take `gem_boss_p1/clip.mp3` of 90.7 s; stretch from 16.0 s, loop 45.000 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.00 LUFS, true peak -2.10 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/music_boss_dark_p2.ogg` (422,140 B) | Gemini app Music skill on 2026-10-17, chat `68e977f6667199c2`, prompt `Instrumental boss escalation loop, 100 BPM, D phrygian dominant, 4/4, seamless 45-second loop. Pulsing distorted bass ostinato, dissonant string-like stabs, metallic industrial hits, rising filter tension. Menacing, urgent, industrial, relentless, bared teeth. No vocals, no lead melody.`; take `gem_boss_p2/clip.mp3` of 178.7 s; stretch from 121.0 s, loop 45.000 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.10 LUFS, true peak -2.30 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/music_boss_dark_p3.ogg` (414,218 B) | Gemini app Music skill on 2026-10-17, chat `57f6ea9383a7fa67`, prompt the recipe's wording was refused ("out of my range", chat `5db8fe3787449bbd`); shipped from `Instrumental climactic industrial loop, 120 BPM, G mixolydian over a low G pedal, 4/4, seamless 45-second loop. Driving industrial percussion, brass-like synth swells, sustained open fifths, rising feedback tones. Desperate, colossal, climactic, defiant. No vocals.`; take `gem_boss_p3/clip.mp3` of 178.3 s; stretch from 61.0 s, loop 45.000 s | Output of the owner's Google account; commercial terms UNVERIFIABLE-HERE (AF6), see the paragraph above | Credited as AI-generated (Google Lyria) on the credits screen; SynthID watermark by Google | Measured after the write: -18.10 LUFS, true peak -2.50 dBFS, mono 44.1 kHz OGG q4 |
| `assets/audio/music/music_combat.ogg` (changed in place, 45.000 s, mono 44.1 kHz OGG) | The audio of the original of `ac45b1c` (provenance unchanged, `docs/CERT_AUDIO.md`): the first relevel of Session 27 (`s27_m2_06dd0c4.relevel.out`) was replaced by one pass from the original with 10 ms edge fades, see the section below | Project-owned, as before | none required | MIX-27, SEAM-27 |

## Changed 2026-10-17 — Session 27 F2: eleven loops with a hard wrap, or a true peak over the canon (the verifier's round)

A loop cut hard clicks where its end meets its start. The verifier's round measured the step at the wrap of every looped file (`python tools/qa_sim/music_post.py --seams`, `docs/artifacts/rc16/proofs/s27_f2_seams_before.out` and `s27_f2_seams_after.out`); each file below stood over a step of 0.05 of full scale or over the canon's true peak, and got 10 ms edge fades and the house law in one pass from its committed original (`s27_f2_seams_fix.out`, `s27_f2_seams_fix2.out`); the format and the length are the original's. SEAM-27.

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/audio/music/layer_dark.ogg` (changed in place, 284,339 B, 118.004 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -18.00 LUFS, true peak -2.60 dBFS, a step of 0.528 at the wrap; after: -17.90 LUFS, true peak -2.60 dBFS, a step of 0.003; the length is the same (118.004 s) |
| `assets/audio/music/music_combat.ogg` (changed in place, 379,411 B, 45.000 s) | The audio of the committed original of `ac45b1c` (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -21.90 LUFS, true peak -2.40 dBFS, a step of 0.442 at the wrap; after: -18.00 LUFS, true peak -3.00 dBFS, a step of 0.003; the length is the same (45.000 s) |
| `assets/audio/music/music_battle.wav` (changed in place, 2,160,978 B, 24.500 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -17.80 LUFS, true peak -2.00 dBFS, a step of 0.164 at the wrap; after: -18.00 LUFS, true peak -2.50 dBFS, a step of 0.000; the length is the same (24.500 s) |
| `assets/audio/music/music_tension.wav` (changed in place, 2,160,978 B, 24.500 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -17.90 LUFS, true peak -1.40 dBFS, a step of 0.115 at the wrap; after: -18.00 LUFS, true peak -2.50 dBFS, a step of 0.000; the length is the same (24.500 s) |
| `assets/audio/music/music_ambient.wav` (changed in place, 4,233,678 B, 48.000 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -18.10 LUFS, true peak -4.70 dBFS, a step of 0.082 at the wrap; after: -18.00 LUFS, true peak -4.60 dBFS, a step of 0.000; the length is the same (48.000 s) |
| `assets/audio/music/music_boss_dark.wav` (changed in place, 2,690,178 B, 30.500 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -16.70 LUFS, true peak -1.50 dBFS, a step of 0.073 at the wrap; after: -18.00 LUFS, true peak -2.80 dBFS, a step of 0.000; the length is the same (30.500 s) |
| `assets/audio/music/layer_threat_low.ogg` (changed in place, 300,927 B, 60.000 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -18.10 LUFS, true peak -1.10 dBFS, a step of 0.050 at the wrap; after: -18.00 LUFS, true peak -2.20 dBFS, a step of 0.000; the length is the same (60.000 s) |
| `assets/audio/music/layer_threat_high.ogg` (changed in place, 462,653 B, 60.000 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -18.10 LUFS, true peak -1.20 dBFS, a step of 0.000 at the wrap; after: -18.00 LUFS, true peak -2.10 dBFS, a step of 0.000; the length is the same (60.000 s) |
| `assets/audio/music/layer_action.ogg` (changed in place, 565,915 B, 60.000 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -18.00 LUFS, true peak -1.30 dBFS, a step of 0.030 at the wrap; after: -18.10 LUFS, true peak -2.20 dBFS, a step of 0.001; the length is the same (60.000 s) |
| `assets/audio/ambience/districts/police_dark.ogg` (changed in place, 320,051 B, 36.000 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -18.10 LUFS, true peak -5.70 dBFS, a step of 0.132 at the wrap; after: -17.90 LUFS, true peak -5.80 dBFS, a step of 0.004; the length is the same (36.000 s) |
| `assets/audio/ambience/districts/industrial_dark.ogg` (changed in place, 54,135 B, 33.994 s) | The audio of the committed original (provenance unchanged, `docs/CERT_AUDIO.md`), put on the law and given 10 ms edge fades by `python tools/qa_sim/music_post.py <file> --relevel --fade-ms 10` on 2026-10-17 (`docs/artifacts/rc16/proofs/s27_f2_seams_fix.out` and `s27_f2_seams_fix2.out`) | Project-owned, as before | none required | Before: -17.90 LUFS, true peak -6.00 dBFS, a step of 0.122 at the wrap; after: -18.00 LUFS, true peak -6.20 dBFS, a step of 0.001; the length is the same (33.994 s) |

## Changed 2026-10-28 — Session 36 art pass 1: ten photo-scanned surfaces (Poly Haven, CC0)

The owner allowed the download of free CC0 textures on 2026-10-28; the sources are not in the tree (`python tools/gen_polyhaven_textures.py <dir>` makes the files from them). Poly Haven publishes every asset under CC0 1.0, a public-domain dedication, so no attribution is owed; the authors are named here as a courtesy. These are photographs of real surfaces, not AI output (the Session 36 AI answer for the stores is unchanged).

| Path | Origin | License | Attribution | Notes |
|---|---|---|---|---|
| `assets/textures/pbr/wet_asphalt_albedo.png`, `_normal.png`, `_rough.png` (512 px) | Poly Haven **Asphalt 02** (asphalt_02), https://polyhaven.com/a/asphalt_02, by Rob Tuytel; the 1k maps downloaded 2026-10-28, sha256 of the sources (first 12 hex): Diffuse=1aa5ce99f58a, nor_gl=42a1c381b532, Rough=70ba3edc6552 | CC0 1.0 (https://polyhaven.com/license) | none required; credited here | Replaces the procedural set of `tools/gen_pbr_textures.py`. Graded by `tools/gen_polyhaven_textures.py`: albedo mean 0.20, saturation x0.45, no texel under 16 or over 216, saturation 0.40 at most; the normal map is the source's OpenGL one, the roughness a grey map between 0.15 and 0.95. Used by: props: none; the wet overlay of the road in rain (WET1). |
| `assets/textures/pbr/cracked_concrete_albedo.png`, `_normal.png`, `_rough.png` (512 px) | Poly Haven **Concrete Layers 02** (concrete_layers_02), https://polyhaven.com/a/concrete_layers_02, by Rob Tuytel; the 1k maps downloaded 2026-10-28, sha256 of the sources (first 12 hex): Diffuse=cca314fbb793, nor_gl=ee35d817b5fa, Rough=1120d3546b60 | CC0 1.0 (https://polyhaven.com/license) | none required; credited here | Replaces the procedural set of `tools/gen_pbr_textures.py`. Graded by `tools/gen_polyhaven_textures.py`: albedo mean 0.38, saturation x0.55, no texel under 16 or over 216, saturation 0.40 at most; the normal map is the source's OpenGL one, the roughness a grey map between 0.15 and 0.95. Used by: no prop names it. |
| `assets/textures/pbr/panel_facade_albedo.png`, `_normal.png`, `_rough.png` (512 px) | Poly Haven **Concrete Wall 007** (concrete_wall_007), https://polyhaven.com/a/concrete_wall_007, by Dario Barresi, Rico Cilliers, Charlotte Baglioni; the 1k maps downloaded 2026-10-28, sha256 of the sources (first 12 hex): Diffuse=1a5ff668a66e, nor_gl=cccb1841908c, Rough=5de46a478cbc | CC0 1.0 (https://polyhaven.com/license) | none required; credited here | Replaces the procedural set of `tools/gen_pbr_textures.py`. Graded by `tools/gen_polyhaven_textures.py`: albedo mean 0.44, saturation x0.55, no texel under 16 or over 216, saturation 0.40 at most; the normal map is the source's OpenGL one, the roughness a grey map between 0.15 and 0.95. Used by: no prop names it; its luminance is the texture of the sidewalk (below). |
| `assets/textures/pbr/rusted_metal_albedo.png`, `_normal.png`, `_rough.png` (512 px) | Poly Haven **Rust Coarse 01** (rust_coarse_01), https://polyhaven.com/a/rust_coarse_01, by Dimitrios Savva, Rico Cilliers; the 1k maps downloaded 2026-10-28, sha256 of the sources (first 12 hex): Diffuse=369f69eb86a7, nor_gl=08ae69576b45, Rough=f5b4a23044af | CC0 1.0 (https://polyhaven.com/license) | none required; credited here | Replaces the procedural set of `tools/gen_pbr_textures.py`. Graded by `tools/gen_polyhaven_textures.py`: albedo mean 0.30, saturation x0.90, no texel under 16 or over 216, saturation 0.40 at most; the normal map is the source's OpenGL one, the roughness a grey map between 0.15 and 0.95. Used by: barrels, bins, hydrants, lamp poles of the district dressing. |
| `assets/textures/pbr/painted_brick_albedo.png`, `_normal.png`, `_rough.png` (512 px) | Poly Haven **Brick 4** (brick_4), https://polyhaven.com/a/brick_4, by Rob Tuytel; the 1k maps downloaded 2026-10-28, sha256 of the sources (first 12 hex): Diffuse=8b2492a04834, nor_gl=214e72192245, Rough=4d0154dc4178 | CC0 1.0 (https://polyhaven.com/license) | none required; credited here | Replaces the procedural set of `tools/gen_pbr_textures.py`. Graded by `tools/gen_polyhaven_textures.py`: albedo mean 0.38, saturation x0.60, no texel under 16 or over 216, saturation 0.40 at most; the normal map is the source's OpenGL one, the roughness a grey map between 0.15 and 0.95. Used by: no prop names it. |
| `assets/textures/pbr/dead_grass_albedo.png`, `_normal.png`, `_rough.png` (512 px) | Poly Haven **Forest Ground 01** (forrest_ground_01), https://polyhaven.com/a/forrest_ground_01, by Rob Tuytel; the 1k maps downloaded 2026-10-28, sha256 of the sources (first 12 hex): Diffuse=3dd6875cb390, nor_gl=32528a7cdee9, Rough=30d8b56a03d7 | CC0 1.0 (https://polyhaven.com/license) | none required; credited here | Replaces the procedural set of `tools/gen_pbr_textures.py`. Graded by `tools/gen_polyhaven_textures.py`: albedo mean 0.25, saturation x0.60, no texel under 16 or over 216, saturation 0.40 at most; the normal map is the source's OpenGL one, the roughness a grey map between 0.15 and 0.95. Used by: no prop names it. |
| `assets/textures/pbr/plywood_albedo.png`, `_normal.png`, `_rough.png` (512 px) | Poly Haven **Wood Planks Dirt** (wood_planks_dirt), https://polyhaven.com/a/wood_planks_dirt, by Rob Tuytel; the 1k maps downloaded 2026-10-28, sha256 of the sources (first 12 hex): Diffuse=230bb4aabaeb, nor_gl=877bf561c0bc, Rough=f9b706729bb7 | CC0 1.0 (https://polyhaven.com/license) | none required; credited here | Replaces the procedural set of `tools/gen_pbr_textures.py`. Graded by `tools/gen_polyhaven_textures.py`: albedo mean 0.32, saturation x0.85, no texel under 16 or over 216, saturation 0.40 at most; the normal map is the source's OpenGL one, the roughness a grey map between 0.15 and 0.95. Used by: crates and benches of the district dressing. |
| `assets/textures/pbr/ceramic_tile_albedo.png`, `_normal.png`, `_rough.png` (512 px) | Poly Haven **Worn Tile Floor** (worn_tile_floor), https://polyhaven.com/a/worn_tile_floor, by Dimitrios Savva; the 1k maps downloaded 2026-10-28, sha256 of the sources (first 12 hex): Diffuse=37ae54f7dc68, nor_gl=8cd189cff118, Rough=92a3cfb16835 | CC0 1.0 (https://polyhaven.com/license) | none required; credited here | Replaces the procedural set of `tools/gen_pbr_textures.py`. Graded by `tools/gen_polyhaven_textures.py`: albedo mean 0.48, saturation x0.60, no texel under 16 or over 216, saturation 0.40 at most; the normal map is the source's OpenGL one, the roughness a grey map between 0.15 and 0.95. Used by: no prop names it. |
| `assets/textures/environment/asphalt.png` (1024 px, grey) | Poly Haven **Asphalt 04** (asphalt_04), https://polyhaven.com/a/asphalt_04, by Jenelle van Heerden, Sergej Majboroda; the 1k diffuse map downloaded 2026-10-28, sha256 (first 12 hex) Diffuse=837a78bb1e94 | CC0 1.0 | none required; credited here | The luminance of the scan, mean 0.19 and a spread of 0.22 around it; the road shader of `scripts/world/street_builder.gd` reads only that around the tint of the tile (`mean_lum` 0.0316). Replaces the 256 px procedural tile. |
| `assets/textures/environment/concrete.png` (1024 px, grey) | Poly Haven **Concrete Wall 007** (concrete_wall_007), https://polyhaven.com/a/concrete_wall_007, by Dario Barresi, Rico Cilliers, Charlotte Baglioni; the 1k diffuse map downloaded 2026-10-28, sha256 (first 12 hex) Diffuse=1a5ff668a66e | CC0 1.0 | none required; credited here | The luminance of the scan, mean 0.37 and a spread of 0.14 around it, for the sidewalk (`mean_lum` 0.1156). Replaces the 256 px procedural tile. |

## Art pass 2 (2026-10-28, arena release agent)

The 29 repainted 2D files of `docs/ART_PASS_2.md` (menu hero, five screen backdrops, city map, grid panel, 11 district cards, 11 locked variants) are AI-generated imagery produced in this pass and are the project's own assets; the style canon and the locked-variant derivation are recorded there. They replace earlier generated/painted files at the same paths; no third-party licence is involved. Environment textures remain the CC0 Poly Haven scans of art pass 1 with their rows above. **Review note (Session 37):** the pass did not record which generator, model version or prompts made the images (it ran in a sandbox without the engine), so the output terms of that tool cannot be cited here (UNVERIFIABLE-HERE: the owner names the tool before the store listing). The images are machine output, so the stores' AI-content answer covers them as it covers the music (`docs/store/HUMAN_CHECKLIST.md`), and a work with no human author may carry no copyright of its own in some jurisdictions, the United States among them.
