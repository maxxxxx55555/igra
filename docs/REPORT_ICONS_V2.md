# REPORT_ICONS_V2 — UI SKIN V2 session (icons + maps + portraits; visual only, zero mechanics)

Session: 2026-08-24. Strictly additive: only NEW folders assets/textures/{icons_v2,maps_v2,portraits_v2} + these two docs. No existing folders, code, scenes, data, or git touched. All files deterministic generator %TEMP%/opencode/tls_gen/gen_icons_v2.py, QA via qa_icons_v2.py — final result PASS.

Design language V2 (canon block was NOT supplied in the brief — derived; see ERROR_LOG_ICONSV2.md DEFAULT_CHOICE marks): line-art 1.5–3px strokes, bone #d8d2c4 primary, olive #8f9464 secondary, brass #c9a24a accents, ember #b4452f threat accents, teal #4a9ab5 tech accents. Textless. Transparent icon backgrounds.

## T1 — Line-art icons (assets/textures/icons_v2/)

| File(s) | Count | Size | Status | Consumer hint |
|---|---|---|---|---|
| district_[id]_64.png (suburbs, residential, park, school, hospital, gas_station, police, warehouses, industrial, substation, power_station) | 11 | <1 KB each | OK | Map screen district pins / district select |
| monster_[id]_64.png (shadow, crawler, watcher, hunter, destroyer, boss) | 6 | <1 KB | OK | Bestiary/encyclopedia list, map threat blips |
| backpack_128, flashlight_128, battery_pack_128, medkit_128, tools_128, key_128, document_128, cassette_128, photo_128, coin_single_128 | 10 | 1–2 KB | OK | Inventory/shop grid (data/items mapping: battery_pack→battery, tools→tool, cassette→audio_log, coin_single→coin, backpack→backpack_l1/l2) |
| upgrade_[param]_48.png (brightness, range, angle, drain, stability, capacity) | 6 | <1 KB | OK | Shop upgrade cards / workbench (params verified in flashlight_stats.tres + shop upgrades) |
| stat_[id]_64.png (clock, district, document, skull, wrench) | 5 | <1 KB | OK | HUD stat row, journal headers, quest filters |
| ctrl_[id]_64.png (flashlight, interact, run, crouch, jump, dodge) | 6 | <1 KB | OK | Touch control hints / onboarding / settings keybinds |
| event_[id]_48.png (siren, breaker, blackout) | 3 | <1 KB | OK | Event toasts / radio log / HUD alerts |
| ach_medal_v2_[01..20]_96.png | 20 | 1 KB | OK | Achievements screen (count grep-corrected 12→20: achievements_manager.gd defines ach_01..ach_20; medal NN ↔ ach_NN) |

## T2 — Map art (assets/textures/maps_v2/)

| File | Size | Status | Consumer hint |
|---|---|---|---|
| city_iso_2048.png | 123 KB | OK | Map screen backdrop: isometric night city, dark blocks, sparse brass light dots + 5 teal pings; zones/lines/labels rendered by engine on top (textless) |
| grid_panel_512.png | 4 KB | OK | Power-grid panel background: dark schematic + pylon silhouettes + brass line nodes (PowerGrid UI) |

## T3 — Monster portraits (assets/textures/portraits_v2/)

| File | Size | Status | Consumer hint |
|---|---|---|---|
| shadow_full_512x768.png | 10 KB | OK | Bestiary full-body: cloaked, teal eye pair + teal rim |
| crawler_full_512x768.png | 7 KB | OK | low quadruped, teal spine rim + ember eye |
| watcher_full_512x768.png | 12 KB | OK | tall thin, single ringed eye |
| hunter_full_512x768.png | 8 KB | OK | upright, ember eyes + claw arcs, brass rim |
| destroyer_full_512x768.png | 8 KB | OK | hulking blocky, ember eyes, teal rim |
| boss_full_512x768.png | 13 KB | OK | robed architect, brass arc halo + brass rim |

All portraits: near-black bg (#080a0d–#0c0f14, no pure black), full-body standing renders, distinct silhouettes (worst accent-mask IoU 0.182).

## T4 — QA results (all PASS)

- Counts vs grep: districts 11/11 (data/districts/district_*.tres), monsters 6/6 named ids all present in data/monsters/*.tres (bestiary.json legacy ids noted, not used), achievements 20/20 (grep-corrected from brief's 12), items 10 (brief-pinned names, data/items mapping above), upgrade params 6/6 (flashlight_stats.tres: cone_angle_deg/drain_per_sec/stability + shop brightness/capacity/range).
- Budget: largest file 123 KB (city_iso_2048) ≤ 500 KB; all others ≤ 13 KB.
- Palette scan (visible pixels): 0 pure #000/#fff; max channel 246 (no neon).
- Readability at 24/32/64 px: coverage + luminance-contrast thresholds met by all 67 icons after fix loop (attempt 2 fixed thin glyphs, attempt 3 two-tone bolt/cross + bigger ctrl glyphs).
- Distinctness (IoU @32px): monsters 0.445, medals inner-pattern 0.890, portraits accents 0.182 — all < 0.90 cap.
- Textless: no glyphs/letters drawn anywhere (verified by construction + visual contact sheets).
