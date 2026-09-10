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
`audio/music/abandoned_hallways_alt.mp3`) were produced in-house by earlier sessions
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
`audio/music/music_ambient_dark.wav`) were produced in-house by earlier sessions
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
`audio/music/music_ambient_dark.wav`) were produced in-house by earlier sessions
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
