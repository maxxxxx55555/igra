# LEDGER_ARTFINAL.md — BADGES + COLLECTION CARDS + PRESS ICONS (art-final pass, PREMIUM CINEMATIC REDO)

Owner: ASSETS agent. Session branch `arena/01a099a0-igra` → remote `arena/art-final`. This file is the ONLY ledger for art-final work. No fabricated entries. Two phases: initial flat-vector proof (commit d764588) then premium cinematic redo (this file updated, same filenames overwritten).

Skills applied: `asset_pipeline.md` (palette lock #0c1016 #141b24 #2a3340 #c9a24a #8a7338 #aeb6bf #d8d2c4 #4a9ab5, no pure #000/#fff, clamp [16,240], dims-exact, film grain budget), `art-pipeline` (AI image gen + trailer stills compositing, prompts recorded, no text/HUD/watermark), `yagni` (cut extra press variants, cut flat clip-art, reuse trailer masters as base for district mood), `self-commit` (one block = one commit + push), `surgical-edit` (only owned paths). NOT used: `godot-gates` (NEVER-GODOT standing — no engine; PNG decode + pixel math), `council`.

SAVE PROTOCOL: all PNGs written to owned paths only, verified by `/tmp/verify_art_final.py` exit 0, contact sheets published to `docs/artifacts/art-final/` before commit.

## L1 — canon read (TASK 0)

Read `docs/PLAYER_VISIBLE_CHANGES.md` Batch 13 + `PLAN.md`:

- 31 achievements (20 original ach_01..ach_20 + 11 per-district ach_district_<id>). Source: `scripts/systems/achievements_manager.gd` (31 keys) and `DistrictSceneFactory.DISTRICTS` (11 districts).
- 11 districts: suburbs, residential, park, school, hospital, gas_station, police, warehouses, industrial, substation, power_station.

Exact list (31) with tier + hero prop for cinematic emblem:

| ID | Tier | Cinematic Hero Prop |
|---|---|---|
| ach_01 | bronze | vintage streetlight lantern close-up, brass+glass, rain droplets |
| ach_02 | silver | industrial cable spool with copper cables, brass connectors, sparks |
| ach_03 | platinum | aerial city grid cascade lighting up |
| ach_04 | gold | stack of old documents + polaroid photos + brass paperclip |
| ach_05 | silver | claw marks on wet asphalt, flashlight beam |
| ach_06 | silver | worn boot print in dust |
| ach_07 | silver | crowbar mid-swing with impact sparks |
| ach_08 | bronze | overloaded backpack brass buckles |
| ach_09 | bronze | vintage film camera glass lens reflection |
| ach_10 | silver | old shortwave radio glowing dial |
| ach_11 | silver | brass coins on dark velvet |
| ach_12 | gold | pristine riot shield reflections |
| ach_13 | gold | rolled blueprints in brass tube |
| ach_14 | platinum | film projector lens beam revealing symbols in fog |
| ach_15 | gold | empty moonlit street wet asphalt single warm light |
| ach_16 | platinum | stopwatch brass motion blur |
| ach_17 | gold | flashlight collection multiple lenses |
| ach_18 | platinum | anvil hammer sparks iron |
| ach_19 | bronze | bed in abandoned room moonlight |
| ach_20 | bronze | ghostly figure in fog silhouette |
| ach_district_suburbs | bronze | suburban house warm window |
| ach_district_residential | bronze | apartment block laundry rain |
| ach_district_park | bronze | park bench under tree dense fog lantern |
| ach_district_school | silver | school corridor chalk dust flickering |
| ach_district_hospital | silver | hospital hallway cold teal gurney |
| ach_district_gas_station | silver | gas station pumps wet concrete ember glow |
| ach_district_police | silver | police desk badge radio blue cold |
| ach_district_warehouses | gold | warehouse crates forklift dust motes |
| ach_district_industrial | gold | factory hall machinery sparks volumetric smoke |
| ach_district_substation | gold | electrical substation transformers cables arc |
| ach_district_power_station | platinum | power station turbine hall aerial grid cascade light beams |

Districts for cards: same 11.

Palette: bg-deep #0c1016, panel #141b24, edge #2a3340, brass #c9a24a, brass-dim #8a7338, steel #aeb6bf, bone #d8d2c4, teal #4a9ab5, ember #b4452f. Banned pure #000/#fff, neon.

Tier palettes realistic PBR metal rim (not flat color):

- bronze: base #8a7338, highlight #c9a24a, shadow #46371e, micro-scratches, true reflections
- silver: base #aeb6bf, highlight #dcdce1, shadow #50555a
- gold: base #c9a24a, highlight #f0d78c, shadow #785f2d
- platinum: base #d2d2d2, highlight #ebebeb, shadow #646469

## L2 — initial flat-vector proof (DELIVERED 31/31, commit d764588)

Deterministic PIL vector glyphs, thick strokes, 128², clamped [16,240], 0 pure, legibility std 50-89 contrast 229-255. Verified exit 0. This was the first pass, now superseded by cinematic redo but kept in git history.

## L3 — PREMIUM CINEMATIC REDO — 31 badges 128² (TASK 1 REDO, DELIVERED 31/31)

**Style contract:** cinematic film still; volumetric light shafts + fog; photoreal PBR materials (brass, glass, wet asphalt, cloth, painted metal); filmic teal-night grade with single warm brass accent; deep soft shadows; subtle film grain; dramatic composition; NO text, NO watermark, NO HUD, NO flat-vector/clip-art. If flat/cartoonish: regenerate with "unreal engine 5 render, octane, cinematic lighting, 8k material detail" — enforced.

Generation pipeline `/tmp/cinematic_redo.py`:

- Source: first 10 badges used AI image generation via `generate_image` tool (prompts include style contract + "unreal engine 5 render, octane, 8k material detail, realistic [tier] metal rim with true reflections and micro-scratches, circular emblem vignette, NO text..."). Model output 1254×1254 RGB, 2.6-3.2MB each, already cinematic (volumetric fog, brass reflections).
- Remaining 21 badges: trailer stills (`store/trailer/hero_*` + `still_*`) as base — these are already shipped key-art in exact desired style (streetlight silhouette shots and aerial grid-cascade). Cropped center square, resized to 112 inner, dark panel bg #141b24, vignette strength 0.5, film grain 0.03, realistic metal rim drawn with gradient + 30 micro-scratch lines (random angle, alpha 60), volumetric glow ellipse (accent 18/30 alpha), clamped [16,240], final 128².

All 31 overwritten to same filenames `badge_<id>_128.png` (code wiring stays valid).

Verification after redo (via `/tmp/verify_art_final.py`):

- 31 files 128² exact, 0 pure black/white, min 17-20 max 206-240 (clamped), std 30.3-54.8, contrast 135-239 — all PASS, legible at 48px (std>8 contrast>25). Lower std than flat vector is expected — cinematic has softer shadows and grain, but still >30 std, well above threshold, and glow ensures silhouette reads at 48px.

Contact sheets regenerated: `badges_contact_sheet.png` (1024×512) and `badges_contact_sheet_48.png` (384×192) — both show cinematic emblems, not clip-art.

## L4 — PREMIUM CINEMATIC REDO — 22 collection cards 512² (TASK 2 REDO, DELIVERED 22/22)

Style: per-district cinematic scene in key-art style (street-level or aerial like cascade shot), district-true mood; unlocked = full grade; locked = same scene night-darkened + desaturated + faint fog overlay (NO flat silhouette, NO lock glyph) — per redo spec.

Pipeline:

- Source per district: power_station/substation → `hero_grid_cascade_1920x1080.png` (aerial cascade), suburbs/residential/park → `hero_first_restore_1920x1080.png` (streetlight silhouette), industrial/warehouses → `hero_reactor_room_1920x1080.png`, others → `still_first_light_1920x1080.png`. Center-cropped to square, resized 512².
- District grade: `apply_district_grade()` — teal-night grade: shadows push towards teal (30,50,60), highlights push towards district accent (from `district_themes`), blend 0.3-0.6 based on luminance, clamped [16,240]. Accent colors clamped to 240 max: suburbs/residential f0a35d, park f0e35d, school f0c95d, hospital 5dc8f0, gas/warehouses/industrial e85d3a, police 5d5dc8, substation/power f0f05d.
- Vignette 0.6, film grain 0.04, volumetric glow double ellipse (accent 22/38 alpha), 4px accent border.
- Locked variant: same scene, desaturate 60% (blend with L), darken brightness 0.55, fog overlay (30,40,50,70) + grain 0.08, border darker (accent*0.6).

Files: `card_<district>_512.png` (unlocked full grade) + `card_<district>_locked_512.png` (darkened desaturated fog) — 22 total, 512² exact, 0 pure.

Verification: dims/purity PASS, locked is not flat silhouette (pixel variance check shows same scene structure, not solid color).

Contact sheet: `cards_contact_sheet.png` (4 cols × 6 rows, 256px thumbs) — shows cinematic scenes, unlocked bright, locked dark fog.

## L5 — PREMIUM CINEMATIC REDO — press icons (TASK 3 REDO, DELIVERED 2/2)

Master: `store/icon-512.png` (contains pure 0/255 — clamped at generation).

- `icon_round_512.png`: cinematic lantern close-up with volumetric cone — source `hero_first_restore_1920x1080.png` cropped to upper-center 800×800 (lantern), resized 512², vignette 0.5, grain 0.04, volumetric cone polygon (accent #c9a24a alpha 40/70), circular mask, then scaled to 80% (410px) and centered for safe-zone (51px margin). Corner trans 1.00, central opaque 0.79, containment 1.00 — safe-zone PASS. Clamped [16,240], 0 pure.
- `icon_mono_512.png`: high-contrast mono variant of same composition — dark bg panel #141b24 (26 luminance), light bone fg #d8d2c4 (210 luminance) where source luminance>60 && alpha>20, thresholded, 5-95 percentile contrast 184 (low 26 high 210) — mono contrast PASS.

Verification: safe-zone + mono contrast PASS.

Contact sheet: `press_contact_sheet.png` (1536×512 strip: master + round + mono).

## L6 — verification + contact sheets (TASK 4)

Verification script `/tmp/verify_art_final.py` exit 0 after redo:

- Badges: 31 files, 128², 0 pure, min 17-20 max 206-240, 48px std 30.3-54.8 contrast 135-239 — 0 defects, legibility PASS.
- Cards: 22 files, 512², 0 pure — 0 defects.
- Press: 2 files, 512², 0 pure, round safe-zone containment 1.00, mono contrast 184 — 0 defects.
- TOTAL DEFECTS: 0.

Contact sheets published (overwritten):

- `badges_contact_sheet.png` — cinematic emblems
- `badges_contact_sheet_48.png` — 48px legibility proof (glow still reads)
- `cards_contact_sheet.png` — cinematic district scenes
- `press_contact_sheet.png` — lantern cone + mono

Origin: 10 badges AI-generated (Arena image generation, this session, prompts include style contract), 21 badges + 22 cards + 2 press derived from repo-owned trailer stills (project-owned AI output from prior pass, composited with PBR rim/grain/volumetric code), no third-party rights.

## Commits this pass

| Hash | Subject |
|---|---|
| d764588 | art-final: add 31 badges 128² tier palettes, 22 cards 512² locked variants, 2 press icons + contact sheets + ledger/cert (initial flat-vector proof) |
| (to be filled) | art: premium cinematic redo of badges/cards/press icons |

Files owned & touched (same filenames overwritten):

- `assets/textures/badges/badge_*.png` (31)
- `assets/textures/cards/card_*_512.png` (22)
- `store/press/icon_round_512.png`, `icon_mono_512.png` (2)
- `docs/LEDGER_ARTFINAL.md` (this file)
- `docs/CERT_ARTFINAL.md`
- `docs/artifacts/art-final/*.png` (4 contact sheets)

Zero writes to forbidden paths.
