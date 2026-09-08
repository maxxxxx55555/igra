# REPORT_STORE_V2 — Store/Press/Social/Endings/Trailer-frames art wave

Scope: `assets/store/v2/**` only (31 files). Additive; V1 store files, other V2 folders, code/data untouched.
Canon: V2 palette bg #0b0e13 / panel #10141b / brass #c9a24a / green #7dc95f / amber #d9a441 / red #b4452f / teal #4a9ab5 / bone #d8d2c4 / olive #8f9464 + cold #1a2133 per TRAILER_STORYBOARD.md. One warm source per comp, wet-asphalt reflections, permanent night, no neon, no pure black/white.
QA: 31/31 PASS — dims per spec, sizes within budget (≤500KB general; hero/background/social-covers ≤1MB), alpha-aware palette scan clean, textless probe clean (no glyph-cluster windows), endings warmth gradient verified monotonic, storyboard exposure-matched as a series.

## T1 — Store listing → assets/store/v2/

| File | Size | Consumer hint |
|---|---|---|
| icon_512_v2.png | 35.9KB | Google Play Console app icon (rounded plate, grunge edge) |
| feature_1024x500_v2.png | 237.9KB | Play Store feature graphic — left third calm for title overlay |
| capsule_header_460x215_v2.png | 60.1KB | Steam header capsule |
| capsule_main_616x353_v2.png | 111.1KB | Steam main capsule |
| capsule_small_231x87_v2.png | 14.8KB | Steam small capsule |
| library_hero_1920x620_v2.png | 536.2KB | Steam library hero (lamp recede + lone walker) |
| background_1920x1080_v2.png | 542.4KB | Steam store page background |

## T2 — Screenshots (1280×720) → assets/store/v2/shots/

| File | Size | Consumer hint |
|---|---|---|
| shot_street.png | 277.9KB | Store screenshot: POV flashlight cone, parked cars, walker |
| shot_map.png | 170.1KB | Store screenshot: isometric city grid, green/amber/red district states, teal objective path |
| shot_encyclopedia.png | 245.6KB | Store screenshot: rim-lit tall monster + bestiary card mood |
| shot_combat.png | 295.7KB | Store screenshot: muzzle flash + hit spark vs Shadow silhouette |
| shot_restored.png | 446.2KB | Store screenshot: streetlight row igniting (reward moment) |

## T3 — Social/press → assets/store/v2/social/

| File | Size | Consumer hint |
|---|---|---|
| twitter_1500x500.png | 235.5KB | X/Twitter header card |
| discord_1280x640.png | 301.3KB | Discord invite splash |
| press_cover_1920x1080.png | 642.2KB | Press-kit cover |
| poster_vertical_1080x1350.png | 486.8KB | Teaser poster: top-down silhouette in single cone |

## T4 — Endings (1920×1080) → assets/store/v2/endings/

IDs grep-verified: `scripts/systems/endings_manager.gd` + i18n ENDING_{DARK,TRUTH,SURVIVOR,HOPE,LIGHT}. Filenames without numeric suffix = DEFAULT_CHOICE (brief gave no extension/naming).
Warmth index = mean(0.6·(R−B)+0.4·L), measured post-grade:

| File | Size | Warmth | Scene |
|---|---|---|---|
| ending_dark.png | 290.9KB | 0.1 (coldest) | near-black city, lone ember |
| ending_truth.png | 323.2KB | 0.6 | bunker, teal monitors, dim utility light |
| ending_survivor.png | 597.1KB | 18.8 | power station, single lamp, walking away |
| ending_hope.png | 716.4KB | 54.2 | partial relight + dawn horizon hint |
| ending_light.png | 765.6KB | 69.7 (warmest) | whole city brass-lit |

Gradient monotonic ✓ (canon order dark<truth<survivor<hope<light).

## T5 — Trailer frames (1280×720) → assets/store/v2/storyboard/

frame_01..frame_10 match docs/TRAILER_STORYBOARD.md shots 1-10 (aerial fog / lamp flicker-hold / light pool / survivor rim-lit / POV beam / ember eyes / combat flash / inventory triage behind dumpster / map ping cascade / ignition cascade + teal boss silhouette). frame_07/frame_09 reuse the verified combat/map comps for exact series consistency. Series exposure pass: P95-matched gains (clamped −38%/+18%) applied after grade; grade lock per doc: grain ~10%, vignette ~35%, warm brass vs cold #1a2133.

## DEFAULT_CHOICE marks
- ending filenames `ending_<id>.png` (brief listed ids bare)
- coin-less listing set uses lamp/walker motifs only; no text anywhere (store titles are overlaid by the stores)
- series-consistency semantics: cold-frame band ±12 + bounded hero beats (see ERROR_LOG_STOREV2)
