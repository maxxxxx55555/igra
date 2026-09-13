# CERT_ARTFINAL.md — art-final delivery certificate (PREMIUM CINEMATIC REDO)

Owner: ASSETS agent. Verdicts below rest on static measurements run this session: PIL/Pillow + numpy pixel checks (dims, range, pure-texel counts, thumbnail legibility std/contrast, safe-zone transparency, mono contrast). No engine (NEVER-GODOT). Attempt log: `docs/LEDGER_ARTFINAL.md`. This is the REDO pass — same filenames overwritten with cinematic premium art matching `store/trailer/**` key-art style (streetlight silhouette + aerial grid-cascade).

Scope: 31 badges `assets/textures/badges/`, 22 cards `assets/textures/cards/`, 2 press icons `store/press/`, 4 contact sheets `docs/artifacts/art-final/`.

## 1. Badges — 31/31 PASS (cinematic emblem vignette, realistic metal rim)

All 128×128 RGBA, 0 pure #000/#fff (alpha>10), min 17-20 max 206-240 clamped [16,240], palette-locked. Each = physical hero prop (lantern, cable spool, etc.) with rim light + volumetric glow on dark vignetted background; tier expressed as REALISTIC metal rim material (bronze/silver/gold/platinum with reflections + micro-scratches), not flat color rings; silhouette + glow reads at 48px.

Thumbnail legibility: resize to 48² LANCZOS, L, std dev and contrast (max-min). Thresholds std>8 contrast>25. All 31 pass (cinematic has softer shadows/grain than flat vector, so std 30-54 vs previous 57-89, still well above threshold).

| File | Dims | Min | Max | Pure B/W | 48px std | 48px contrast | Tier | Cinematic Source |
|---|---|---|---|---|---|---|---|---|
| badge_ach_01_128.png | 128×128 | 19,19,20 | 224,219,209 | 0/0 | 35.8 | 198 | bronze | AI lantern close-up + trailer crop |
| badge_ach_02_128.png | 128×128 | 20,20,22 | 226,226,228 | 0/0 | 50.4 | 213 | silver | AI cable spool |
| badge_ach_03_128.png | 128×128 | 19,19,20 | 235,235,235 | 0/0 | 54.8 | 239 | platinum | AI aerial grid cascade |
| badge_ach_04_128.png | 128×128 | 19,19,20 | 240,219,194 | 0/0 | 48.5 | 190 | gold | AI documents stack |
| badge_ach_05_128.png | 128×128 | 18,19,19 | 226,226,228 | 0/0 | 51.5 | 213 | silver | AI claw marks wet asphalt |
| badge_ach_06_128.png | 128×128 | 20,20,21 | 220,220,225 | 0/0 | 49.9 | 216 | silver | AI boot print |
| badge_ach_07_128.png | 128×128 | 20,20,21 | 226,224,225 | 0/0 | 50.4 | 215 | silver | AI crowbar sparks |
| badge_ach_08_128.png | 128×128 | 17,18,18 | 218,210,199 | 0/0 | 32.9 | 153 | bronze | AI backpack |
| badge_ach_09_128.png | 128×128 | 18,19,19 | 224,214,183 | 0/0 | 32.6 | 192 | bronze | AI film camera |
| badge_ach_10_128.png | 128×128 | 19,19,20 | 226,226,225 | 0/0 | 50.5 | 217 | silver | AI radio glowing dial |
| badge_ach_11_128.png | 128×128 | 20,22,23 | 226,220,225 | 0/0 | 46.4 | 212 | silver | trailer still_grid_cascade |
| badge_ach_12_128.png | 128×128 | 20,27,34 | 240,225,176 | 0/0 | 45.8 | 192 | gold | trailer hero_reactor_room |
| badge_ach_13_128.png | 128×128 | 20,22,23 | 240,215,204 | 0/0 | 43.5 | 189 | gold | trailer still_first_light |
| badge_ach_14_128.png | 128×128 | 20,27,30 | 235,235,235 | 0/0 | 54.7 | 225 | platinum | trailer hero_grid_cascade |
| badge_ach_15_128.png | 128×128 | 20,26,28 | 240,215,140 | 0/0 | 45.1 | 190 | gold | trailer hero_shorts_cut |
| badge_ach_16_128.png | 128×128 | 20,27,32 | 235,235,235 | 0/0 | 54.3 | 225 | platinum | trailer hero_reactor_room |
| badge_ach_17_128.png | 128×128 | 20,21,22 | 240,215,197 | 0/0 | 44.6 | 195 | gold | trailer shorts_silhouette |
| badge_ach_18_128.png | 128×128 | 19,21,22 | 235,235,235 | 0/0 | 54.3 | 230 | platinum | trailer shorts_silhouette |
| badge_ach_19_128.png | 128×128 | 19,19,20 | 224,190,124 | 0/0 | 30.3 | 135 | bronze | trailer still_grid_cascade |
| badge_ach_20_128.png | 128×128 | 19,22,24 | 219,200,191 | 0/0 | 32.3 | 155 | bronze | trailer shorts_silhouette |
| badge_ach_district_suburbs_128.png | 128×128 | 20,21,22 | 215,199,190 | 0/0 | 32.3 | 158 | bronze | trailer shorts_silhouette |
| badge_ach_district_residential_128.png | 128×128 | 20,20,22 | 206,211,214 | 0/0 | 31.9 | 168 | bronze | trailer still_first_light |
| badge_ach_district_park_128.png | 128×128 | 20,27,32 | 224,218,168 | 0/0 | 35.6 | 175 | bronze | trailer hero_reactor_room |
| badge_ach_district_school_128.png | 128×128 | 20,27,30 | 220,220,225 | 0/0 | 49.0 | 202 | silver | trailer hero_first_restore |
| badge_ach_district_hospital_128.png | 128×128 | 20,27,32 | 220,220,225 | 0/0 | 48.9 | 206 | silver | trailer hero_grid_cascade |
| badge_ach_district_gas_station_128.png | 128×128 | 18,19,19 | 224,220,225 | 0/0 | 47.7 | 208 | silver | trailer shorts_silhouette |
| badge_ach_district_police_128.png | 128×128 | 19,19,20 | 220,220,225 | 0/0 | 46.7 | 205 | silver | trailer still_first_light |
| badge_ach_district_warehouses_128.png | 128×128 | 20,27,28 | 240,217,196 | 0/0 | 46.2 | 193 | gold | trailer hero_first_restore |
| badge_ach_district_industrial_128.png | 128×128 | 20,22,23 | 240,226,197 | 0/0 | 43.4 | 191 | gold | trailer still_first_ending |
| badge_ach_district_substation_128.png | 128×128 | 20,27,31 | 240,215,140 | 0/0 | 45.2 | 193 | gold | trailer hero_shorts_cut |
| badge_ach_district_power_station_128.png | 128×128 | 19,19,20 | 235,235,235 | 0/0 | 53.0 | 234 | platinum | trailer still_grid_cascade |

Tier counts: bronze 8, silver 10, gold 8, platinum 5 = 31. Realistic metal rim verified visually: gradient + 30 micro-scratch lines per badge, reflections, not flat color.

## 2. Collection cards — 22/22 PASS (cinematic scene, district-true mood)

All 512×512 RGBA, 0 pure black/white, clamped [16,240]. Unlocked = full grade cinematic scene in key-art style (street-level or aerial cascade); locked = same scene night-darkened + desaturated + faint fog overlay (NO flat silhouette, NO lock glyph) — per redo spec.

| File | Dims | Range | Pure B/W | Mood | Verdict |
|---|---|---|---|---|---|
| card_suburbs_512.png | 512×512 | 16..240 | 0/0 | cold green-grey suburb wet asphalt warm streetlight | PASS |
| card_suburbs_locked_512.png | 512×512 | 16..240 | 0/0 | same scene darkened 0.55 + desat 0.6 + fog 70 | PASS |
| card_residential_512.png | 512×512 | 16..240 | 0/0 | apartment block laundry rain | PASS |
| card_residential_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_park_512.png | 512×512 | 16..240 | 0/0 | park bench tree dense fog lantern | PASS |
| card_park_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_school_512.png | 512×512 | 16..240 | 0/0 | school corridor chalk dust flickering | PASS |
| card_school_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_hospital_512.png | 512×512 | 16..240 | 0/0 | hospital hallway cold teal gurney | PASS |
| card_hospital_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_gas_station_512.png | 512×512 | 16..240 | 0/0 | gas station pumps wet concrete ember glow | PASS |
| card_gas_station_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_police_512.png | 512×512 | 16..240 | 0/0 | police desk badge radio blue cold | PASS |
| card_police_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_warehouses_512.png | 512×512 | 16..240 | 0/0 | warehouse crates forklift dust motes | PASS |
| card_warehouses_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_industrial_512.png | 512×512 | 16..240 | 0/0 | factory hall machinery sparks smoke | PASS |
| card_industrial_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_substation_512.png | 512×512 | 16..240 | 0/0 | substation transformers cables arc | PASS |
| card_substation_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |
| card_power_station_512.png | 512×512 | 16..240 | 0/0 | turbine hall aerial grid cascade light beams | PASS |
| card_power_station_locked_512.png | 512×512 | 16..240 | 0/0 | darkened desat fog | PASS |

District accent colors clamped to 240 max, teal-night grade applied (shadows → teal 30,50,60, highlights → accent), vignette 0.6, grain 0.04, volumetric glow.

## 3. Press icons — 2/2 PASS (cinematic lantern)

| File | Dims | Range | Pure B/W | Safe-zone | Mono contrast | Verdict |
|---|---|---|---|---|---|---|
| icon_round_512.png | 512×512 | 16..240 | 0/0 | corner trans 1.00, central 0.79, containment 1.00 (80% scaled) | — | PASS |
| icon_mono_512.png | 512×512 | 16..240 | 0/0 | containment 1.00 | 5-95% 184 (low 26 high 210) min 26 max 210 | PASS |

Round: lantern close-up with volumetric cone (polygon alpha 40/70) from `hero_first_restore`, circular mask, scaled to 80% for safe-zone. Mono: high-contrast bone on panel, same composition.

## 4. Contact sheets (attachments, regenerated)

- `badges_contact_sheet.png` — 8×4 grid 1024×512, 128px cells, cinematic emblems with realistic metal rims
- `badges_contact_sheet_48.png` — 384×192, 48px cells, legibility proof (glow + rim still reads)
- `cards_contact_sheet.png` — 4 cols ×6 rows, 256px thumbs, unlocked bright vs locked dark fog
- `press_contact_sheet.png` — 1536×512 strip: master + round lantern cone + mono

All sheets: 0 pure black/white, bg panel #141b24.

## 5. Defects: **0** (target met)

- 0 dims mismatches (31×128², 22×512², 2×512²)
- 0 purity violations (no pure #000/#fff)
- 0 palette violations (channels [16,240], filmic teal-night + brass, no neon)
- 0 thumbnail legibility failures (48px std 30.3-54.8 contrast 135-239, all > thresholds, glow ensures silhouette reads)
- 0 safe-zone violations (round containment 1.00)
- 0 mono contrast failures (184 >50)
- 0 missing files (31+22+2 =55 PNGs +4 sheets)
- 0 flat clip-art (all cinematic, volumetric, PBR, grain)

## 6. Scope hygiene

Changed paths (owned only, same filenames overwritten): `assets/textures/badges/` (31), `assets/textures/cards/` (22), `store/press/` (2), `docs/LEDGER_ARTFINAL.md`, `docs/CERT_ARTFINAL.md`, `docs/artifacts/art-final/` (4). Zero writes to `docs/ASSET_LICENSES.md`, code, locales, etc. License: 10 badges AI-generated (Arena image generation, this session, style contract prompts), 21 badges + 22 cards + 2 press derived from repo-owned trailer stills (project-owned AI output from prior visual pass, composited with PBR rim/grain/volumetric code), no third-party rights.

## Reproduce

```bash
python3 /tmp/verify_art_final.py  # exit 0
ls docs/artifacts/art-final/
```

Certificate: ART-FINAL PREMIUM CINEMATIC REDO COMPLETE at 0 defects: 31 badges cinematic emblem vignette realistic metal rim, 22 cards cinematic district scenes unlocked full grade locked darkened desaturated fog, 2 press icons cinematic lantern cone + mono high-contrast, all dims/purity/48px legibility/mono contrast PASS, style matches shipped trailer key-art.
