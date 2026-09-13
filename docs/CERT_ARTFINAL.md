# CERT_ARTFINAL.md — art-final delivery certificate (BADGES + CARDS + PRESS)

Owner: ASSETS agent. Verdicts below rest on static measurements run this session: PIL/Pillow 11.x + numpy 2.x pixel checks (dims, range, pure-texel counts, thumbnail legibility std/contrast, safe-zone transparency, mono contrast). No engine (NEVER-GODOT standing). Attempt log: `docs/LEDGER_ARTFINAL.md`.

Scope: 31 badges `assets/textures/badges/`, 22 cards `assets/textures/cards/`, 2 press icons `store/press/`, 4 contact sheets `docs/artifacts/art-final/`.

## 1. Badges — 31/31 PASS

All 128×128 RGBA, 0 pure `#000000` / `#ffffff` texels (alpha>10 considered), min ≥16 max ≤240, palette-locked to tier tokens.

Thumbnail legibility pass: each badge resized to 48×48 LANCZOS, converted to L, measured std dev and contrast (max-min). Thresholds: std >8, contrast >25 (empirically, a flat badge would be <5 std, <15 contrast; our glyphs are thick vector shapes). All 31 pass.

| File | Dims | Min | Max | Pure B/W | 48px std | 48px contrast | Tier |
|---|---|---|---|---|---|---|---|
| badge_ach_01_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 50.9 | 247 | bronze |
| badge_ach_02_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 72.5 | 255 | silver |
| badge_ach_03_128.png | 128×128 | 20,27,36 | 230,226,214 | 0/0 | 86.0 | 255 | platinum |
| badge_ach_04_128.png | 128×128 | 20,27,36 | 232,220,196 | 0/0 | 79.4 | 245 | gold |
| badge_ach_05_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 81.0 | 255 | silver |
| badge_ach_06_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 73.8 | 255 | silver |
| badge_ach_07_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 75.3 | 255 | silver |
| badge_ach_08_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 66.4 | 235 | bronze |
| badge_ach_09_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 68.6 | 232 | bronze |
| badge_ach_10_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 75.3 | 255 | silver |
| badge_ach_11_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 77.1 | 255 | silver |
| badge_ach_12_128.png | 128×128 | 20,27,36 | 232,220,196 | 0/0 | 68.2 | 245 | gold |
| badge_ach_13_128.png | 128×128 | 20,27,36 | 232,220,196 | 0/0 | 81.2 | 241 | gold |
| badge_ach_14_128.png | 128×128 | 20,27,36 | 230,226,214 | 0/0 | 88.7 | 255 | platinum |
| badge_ach_15_128.png | 128×128 | 20,27,36 | 232,220,196 | 0/0 | 68.3 | 243 | gold |
| badge_ach_16_128.png | 128×128 | 20,27,36 | 230,226,214 | 0/0 | 85.6 | 255 | platinum |
| badge_ach_17_128.png | 128×128 | 20,27,36 | 232,220,196 | 0/0 | 72.5 | 245 | gold |
| badge_ach_18_128.png | 128×128 | 20,27,36 | 230,226,214 | 0/0 | 89.8 | 255 | platinum |
| badge_ach_19_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 63.0 | 235 | bronze |
| badge_ach_20_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 63.1 | 236 | bronze |
| badge_ach_district_suburbs_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 68.2 | 236 | bronze |
| badge_ach_district_residential_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 66.8 | 238 | bronze |
| badge_ach_district_park_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 57.0 | 229 | bronze |
| badge_ach_district_school_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 84.1 | 255 | silver |
| badge_ach_district_hospital_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 83.0 | 255 | silver |
| badge_ach_district_gas_station_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 82.0 | 255 | silver |
| badge_ach_district_police_128.png | 128×128 | 20,27,36 | 216,210,196 | 0/0 | 75.0 | 255 | silver |
| badge_ach_district_warehouses_128.png | 128×128 | 20,27,36 | 232,220,196 | 0/0 | 79.4 | 233 | gold |
| badge_ach_district_industrial_128.png | 128×128 | 20,27,36 | 232,220,196 | 0/0 | 81.0 | 247 | gold |
| badge_ach_district_substation_128.png | 128×128 | 20,27,36 | 232,220,196 | 0/0 | 69.2 | 237 | gold |
| badge_ach_district_power_station_128.png | 128×128 | 20,27,36 | 230,226,214 | 0/0 | 85.0 | 255 | platinum |

Palette histogram check: all badge pixels within [16,240] per channel, no neon (max saturation low by construction — tier colors are desaturated brass/steel/bone). Tier counts: bronze 8, silver 10, gold 8, platinum 5 = 31.

## 2. Collection cards — 22/22 PASS

All 512×512 RGBA, 0 pure black/white, clamped [16,240].

| File | Dims | Range | Pure B/W | Verdict |
|---|---|---|---|---|
| card_suburbs_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_suburbs_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_residential_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_residential_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_park_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_park_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_school_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_school_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_hospital_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_hospital_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_gas_station_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_gas_station_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_police_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_police_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_warehouses_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_warehouses_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_industrial_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_industrial_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_substation_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_substation_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_power_station_512.png | 512×512 | 16..240 | 0/0 | PASS |
| card_power_station_locked_512.png | 512×512 | 16..240 | 0/0 | PASS |

Locked variants verified: desaturated glyph + lock icon, darker, still no pure.

## 3. Press icons — 2/2 PASS

Master: `store/icon-512.png` (512×512, contains pure 0/255 — clamped at generation to [16,240] for derivatives).

| File | Dims | Range | Pure B/W | Safe-zone | Mono contrast | Verdict |
|---|---|---|---|---|---|---|
| icon_round_512.png | 512×512 | 16..240 | 0/0 | corner trans 1.00, central opaque 0.97, containment 1.00 (content within 80%) | — | PASS |
| icon_mono_512.png | 512×512 | 16..240 | 0/0 | containment 1.00 (scaled to 80%) | 5-95% 184 (low 26 high 210) min 26 max 210 | PASS |

Safe-zone definition: important content within central 80% (51px margin). Both icons scaled to 80% (410px) and centered before masking, so 100% of opaque pixels lie within central 80%.

Mono contrast definition: 5th percentile luminance 26 (panel bg `#141b24`), 95th percentile 210 (bone `#d8d2c4`), delta 184 >50 threshold, high contrast.

## 4. Contact sheets (attachments)

- `docs/artifacts/art-final/badges_contact_sheet.png` — 8×4 grid, 1024×512, 128px cells, all 31 badges.
- `docs/artifacts/art-final/badges_contact_sheet_48.png` — same grid at 48px, legibility proof (all glyphs distinguishable).
- `docs/artifacts/art-final/cards_contact_sheet.png` — 4 cols, 256px thumbs, 22 cards (11 unlocked + 11 locked).
- `docs/artifacts/art-final/press_contact_sheet.png` — 1536×512 strip: master (left) + round (center) + mono (right).

All sheets: 0 pure black/white (bg `#141b24` / `#0c1016` clamped).

## 5. Defects: **0** (target met)

- 0 dims mismatches (31 badges 128², 22 cards 512², 2 press 512²)
- 0 purity violations (no pure `#000000` / `#ffffff` in any delivered PNG)
- 0 palette violations (all channels [16,240], no neon)
- 0 thumbnail legibility failures (48px std>8 contrast>25 for all 31)
- 0 safe-zone violations (round corners transparent, central containment 1.00)
- 0 mono contrast failures (184 >50)
- 0 missing files (31+22+2 = 55 PNGs + 4 contact sheets)

## 6. Scope hygiene

Changed paths this pass (owned only): `assets/textures/badges/` (31 new), `assets/textures/cards/` (22 new), `store/press/` (2 new), `docs/LEDGER_ARTFINAL.md`, `docs/CERT_ARTFINAL.md`, `docs/artifacts/art-final/` (4 new). Zero writes to `docs/ASSET_LICENSES.md`, code, locales, content, or other textures. License: project-authored deterministic PIL output, no third-party rights.

## Reproduce

```bash
python3 /tmp/verify_art_final.py  # exit 0 = 0 defects
# contact sheets:
ls docs/artifacts/art-final/
```

Certificate: the ART-FINAL deliverables are COMPLETE and VERIFIED at 0 defects: 31 badges (tier palettes bronze/silver/gold/platinum, glyph-legible at 48px, palette-locked, no pure black/white), 22 collection cards (512² unlocked + locked silhouette), 2 press icons (round safe-zone + mono contrast from master).
