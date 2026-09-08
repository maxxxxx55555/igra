# REPORT_DEVICES_V2 — Device variants + Coming Soon wave

Scope: `assets/store/v2/devices/**` (14 art files) + `assets/store/v2/coming_soon/**` (2). Strictly additive; store/v2 root, ab/, vertical/, youtube/, itch/, yandex/, presskit/ untouched.
Canon: V2 palette + trailer cold #1a2133; compositions adapted from delivered shots/ family (street POV / iso map / combat / lamp-row hero). All textless.
QA: 20/20 PASS — dims exact per device class, ≤500KB each (quantize ladder), alpha-free palette scan clean (no pure black/white), portrait bottom-25% overlay zones calm (std ≤16), Steam TV 4K verified sharper-than-1080p-master (edge 0.0069 vs 0.0043, native render — zero upscale artifacts), Play Console count audit ≥2 per class.

## T1 — Play Console device screenshots → devices/

| File | Size | Consumer hint |
|---|---|---|
| phone/phone_street.png | 370.1KB | Play Console → Phone screenshots (1080×1920; hero upper 60%, bottom 40% calm for Google UI) |
| phone/phone_map.png | 234.0KB | Phone screenshots (portrait isometric grid, district states) |
| phone/phone_combat.png | 372.9KB | Phone screenshots (muzzle flash vs Shadow silhouette) |
| phone/phone_menu.png | 435.8KB | Phone screenshots (menu_hero mood, portrait) |
| tablet_7/tablet_7_map.png | 473.9KB | Play Console → 7" tablet screenshots (1800×2560; extended city grid) |
| tablet_7/tablet_7_encounter.png | 468.1KB | 7" tablet screenshots (POV encounter, ember eyes) |
| tablet_10/tablet_10_street.png | 452.3KB | Play Console → 10" tablet screenshots (2560×1800 landscape street) |
| tablet_10/tablet_10_menu.png | 470.0KB | 10" tablet screenshots (landscape menu_hero adaptation) |

## T2 — Steam device variants → devices/

| File | Size | Consumer hint |
|---|---|---|
| steam_desktop/steam_desktop_hero.png | 361.2KB | Steam library/screenshots slot (1920×1080 hero: lamp row + walker) |
| steam_desktop/steam_desktop_map.png | 369.4KB | Steam screenshots (wide iso power-grid map) |
| steam_desktop/steam_desktop_combat.png | 414.1KB | Steam screenshots (combat comp, full HD re-render) |
| steam_tv/steam_tv_hero_4k.png | 467.8KB | Steam TV / big-picture 3840×2160 — NATIVE 4K render (not upscaled): edge density 0.0069 > accepted-1080p-master 0.0043 |

## T3 — Coming Soon → coming_soon/

| File | Size | Consumer hint |
|---|---|---|
| wishlist_hero_1920x1080.png | 404.2KB | Steam "Coming Soon" page hero + pre-launch marketing. Colder grade than menu_hero (warmth 25.9 vs 52.8 measured); distant skyline dots hint full restoration — "this is before" |
| dlc_teaser_1920x1080.png | 429.3KB | Post-launch mood piece (teal-lit bunker door ⇒ TRUTH path). Standalone-usable; no promise implied |

## DEFAULT_CHOICE marks
- phone_menu / tablet_10_menu are menu_hero-composition portraits/landscape renders (brief said "adapt existing shots")
- itch-style byte-copy not used here; desktop variants are fresh deterministic renders at exact dims (verified separate files)
- wishlist distant-city hint = sparse brass dot field upper-right (no readable structure)
