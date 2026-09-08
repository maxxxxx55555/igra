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

## Audit checklist (run each asset pass)

1. `git diff --stat` binaries vs. this ledger — every row present.
2. Web-sourced rows: license text archived in `docs/reference/` + credit line present.
3. Sizes within budget (PRODUCTION_BIBLE §4): tiles ≤256² / ~500 KB.
4. No pure #000/#fff texels in UI-visible art (STYLE_GUIDE §2).
