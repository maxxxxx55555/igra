# CERT_VISUAL.md — visual delivery certificate (2026-09-11, VISUAL 100/100 pass)

Owner: CONTENT+ASSETS agent. Every verdict below rests on measured facts: PNG
decode + numpy pixel math over the committed artifacts (`/tmp/tls_visual/verify.py`,
exit 0). No engine was run (NEVER-GODOT standing) — correctness is proven by
decode + exact-dimension + pixel-statistics checks, not by a Godot render.

Scope checked: 11 LUTs (`assets/textures/luts/`), 8 screenshots (`store/screenshots/`),
4 re-graded trailer stills (`store/trailer/`). Static checks only (dims, palette, purity,
LUT row-monotonicity); human eyeball of composition remains the owner's QA step per
`store/screenshot-plan-detailed.md` §4.

## 1. LUT static checks — 11/11 PASS

Layout: 256×16 Godot `Environment.color_correction` (16 blue tiles × 16 px; x=red, y=green).
Purity bar: 0 pure `#000000` / `#ffffff` texels; min ≥ 16, max ≤ 240.
Row-monotonicity: per row (fixed green), within each 16-px red segment (fixed blue tile),
each channel non-decreasing in red **and** per column (fixed red/blue), each channel
non-decreasing in green. Defects: **0 across all 11 files**.

| District | Dims | Min | Max | Bytes | Pure black/white | Mono defects |
|---|---|---|---|---|---|---|
| suburbs | 256×16 | 17,17,17 | 216,239,208 | 1546 | 0 / 0 | 0 |
| residential | 256×16 | 17,17,17 | 216,239,208 | 1546 | 0 / 0 | 0 |
| park | 256×16 | 17,17,17 | 211,240,197 | 1510 | 0 / 0 | 0 |
| school | 256×16 | 17,17,17 | 200,204,235 | 1691 | 0 / 0 | 0 |
| hospital | 256×16 | 17,17,17 | 181,203,234 | 1518 | 0 / 0 | 0 |
| gas_station | 256×16 | 17,17,17 | 238,205,178 | 1545 | 0 / 0 | 0 |
| police | 256×16 | 17,17,17 | 179,179,234 | 1504 | 0 / 0 | 0 |
| warehouses | 256×16 | 19,19,19 | 234,210,190 | 1776 | 0 / 0 | 0 |
| industrial | 256×16 | 19,19,19 | 234,210,190 | 1776 | 0 / 0 | 0 |
| substation | 256×16 | 18,18,18 | 240,240,240 | 1613 | 0 / 0 | 0 |
| power_station | 256×16 | 18,18,18 | 240,240,240 | 1613 | 0 / 0 | 0 |

Twin pairs byte-identical (SHA-256): suburbs ≡ residential, warehouses ≡ industrial,
substation ≡ power_station — per spec, those districts differ by prop density / lights,
not grading.

## 2. Screenshot static checks — 8/8 PASS

All 1920×1080, 24-bit PNG, ≤ 8 MB, 0 pure `#000000` / `#ffffff`, max channel ≤ 240,
mean saturation ≤ 40 (no neon). Touch shots additionally: top/bottom 108-px letterbox bars
flat `#0c1016` (verified pixel-exact, 100% of bar area).

| File | Dims | Size | Min | Max | Mean sat | Pure b/w | Letterbox |
|---|---|---|---|---|---|---|---|
| shot01_light_vs_dark_1920x1080_en.png | 1920×1080 | 1.17 MB | 16,16,16 | 226,226,209 | 6.5 | 0 / 0 | — |
| shot02_district_boundary_1920x1080_en.png | 1920×1080 | 1.88 MB | 16,16,16 | 223,218,209 | 8.2 | 0 / 0 | — |
| shot05_restored_forecourt_1920x1080_en.png | 1920×1080 | 1.41 MB | 16,16,16 | 240,237,207 | 23.7 | 0 / 0 | — |
| shot07_last_streetlight_1920x1080_en.png | 1920×1080 | 1.68 MB | 16,16,16 | 240,240,240 | 4.2 | 0 / 0 | — |
| shot08_city_map_1920x1080_en.png | 1920×1080 | 0.13 MB | 10,10,10 | 240,240,235 | 13.5 | 0 / 0 | — |
| shot_p1_touch_first_light_1920x1080_en.png | 1920×1080 | 1.33 MB | 8,10,16 | 240,240,240 | 14.0 | 0 / 0 | flat ✓ |
| shot_p2_touch_crouch_1920x1080_en.png | 1920×1080 | 1.24 MB | 8,10,16 | 216,214,214 | 9.8 | 0 / 0 | flat ✓ |
| shot_p3_touch_interact_1920x1080_en.png | 1920×1080 | 1.16 MB | 8,11,16 | 240,240,214 | 9.3 | 0 / 0 | flat ✓ |

Touch-shot min of 8 (single channel) is the HUD drop-shadow composite (joystick base at
partial alpha over ≥16 content); no pure-black texel exists anywhere (all three channels
0 simultaneously = 0).

## 3. Trailer re-grade checks — 4/4 PASS

Re-graded in place with the per-district LUTs (luma-mix, strength 0.55), then re-clamped.
Mean RGB before → after recorded; dims unchanged; 0 pure black/white; max ≤ 240.

| File | LUT | Mean before (0–1) | Mean after (0–1) | Min | Max | Pure b/w |
|---|---|---|---|---|---|---|
| still_first_light_1920x1080.png | suburbs | .14 .15 .15 | .16 .18 .17 | 18,18,18 | 237,239,237 | 0 / 0 |
| still_first_ending_1920x1080.png | suburbs | .26 .26 .26 | .27 .28 .26 | 18,18,18 | 237,239,237 | 0 / 0 |
| still_grid_cascade_1920x1080.png | power_station | .14 .15 .16 | .17 .18 .19 | 19,19,19 | 239,239,227 | 0 / 0 |
| shorts_silhouette_1080x1920.png | suburbs | .15 .14 .13 | .17 .17 .15 | 18,18,18 | 237,239,237 | 0 / 0 |

`presskit_1600x900.png` is a title+tagline composite over three per-district thumbs, not a
single-mood still — excluded from LUT re-grading by design (a single LUT would mis-grade a
three-district composite).

## 4. Defects: **0** (target met)

- 0 dims mismatches (11 LUTs 256×16; 8 shots 1920×1080; 4 stills exact).
- 0 purity violations (no pure `#000000` / `#ffffff` texel in any delivered PNG).
- 0 palette violations (max channel ≤ 240; mean saturation ≤ 40).
- 0 LUT row-monotonicity defects.
- 0 letterbox deviations (3 touch shots, flat `#0c1016`, pixel-exact).
- 0 size violations (≤ 8 MB each).
