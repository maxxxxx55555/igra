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
