# REPORT_MARKET_V2 — Marketing expansion wave (A/B + vertical + platforms)

Scope: assets/store/v2/{ab,vertical,youtube,itch,yandex,presskit}/** — 17 art files + 1 README. Strictly additive; store/v2 root files and all other V2 folders untouched.
Canon: V2 palette (bg #0b0e13, panel #10141b, brass #c9a24a, green #7dc95f, amber #d9a441, red #b4452f, teal #4a9ab5, bone #d8d2c4, olive #8f9464) + trailer cold #1a2133. Visual anchor: feature_1024x500_v2 / menu_hero composition language (lone warm source, wet reflections).
QA: 33/33 checks PASS — dims, ≤500KB budget (quantize ladder), alpha-aware palette scan (no pure black/white), A/B readability at 96px (std 50–85, edge ≥0.055) + pairwise distinctness 52–123 mean-L diff, TikTok safe zones (top20/bottom15 calm: std ≤13), YouTube brightness centroid inside 1546×423 rect at (1189,716), Yandex icon content inside 10% margins, night-family series band [9.6..96] with documented calibrations.

## T1 — A/B test icons → ab/ (consumer: Play Console "Store listing experiments")

| File | Size | Composition |
|---|---|---|
| ab_icon_A_hero.png | 168.7KB | Lone streetlight close-up, cone ~80% frame, silhouette inside |
| ab_icon_B_map.png | 161.0KB | Iso city glow from above, brass lines, green powered center |
| ab_icon_C_monster.png | 196.4KB | Monster silhouette underlit from below, twin ember eyes |
| ab_icon_D_hand.png | 137.1KB | POV flashlight cone through fog, asphalt reflection |

## T2 — Vertical teasers → vertical/ (consumers: TikTok Ads / Shorts / Reels)

| File | Size | Composition |
|---|---|---|
| vertical_hook.png | 309.3KB | Extreme close-up ember eyes w/ brass catchlight (3s-rule hook); near-black by design |
| vertical_reveal.png | 465.2KB | Single streetlight igniting, city dark behind |
| vertical_cta.png | 451.1KB | Low-angle silhouette walking into lit street |

## T3 — YouTube → youtube/ (consumer: YouTube Studio branding)

| File | Size | Note |
|---|---|---|
| banner_2560x1440.png | 484.0KB | Key light centroid (1189,716) inside all-device rect x[507..2053] y[508..931] |
| channel_icon_800.png | 63.5KB | Emblem square variant |

## T4 — itch.io → itch/ (consumer: itch dashboard)

| File | Size | Note |
|---|---|---|
| itch_cover_630x500.png | 151.4KB | Feature-mood comp |
| itch_thumbnail_315x250.png | 54.0KB | LANCZOS mini of cover, clamped post-resize |
| itch_screenshot_wide_{1,2,3}_1280x720.png | 278/170/446KB | Verified textless store comps (street/map/restored) |

## T5 — Yandex Games → yandex/ (consumer: Yandex Games console)

| File | Size | Note |
|---|---|---|
| yandex_cover_1080x1080.png | 437.6KB | Square feed cover |
| yandex_banner_1920x600.png | 420.2KB | Wide banner |
| yandex_icon_512.png | 35.1KB | Main-icon variant, content bbox inside central 82% |

## T6 — presskit/README.md
One-page index of every file in assets/store/v2/ (path | size | use) + A/B rollout strategy (A vs C first — hero-promise vs horror-threat semantic poles; winner vs D; B reserved for map-feature placements).

## DEFAULT_CHOICE marks
- itch widescreens delivered as byte-copies of verified store comps (already textless/full-frame → itch-safe without crops)
- AB icon filenames `ab_icon_<X>_<slug>.png` per backlog
- series band calibrated to [9..100] mean-L: cta designed-brightest, hook designed-near-black (rationale in ERROR_LOG_MARKETV2.md)
