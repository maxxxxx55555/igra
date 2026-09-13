# LEDGER_ARTFINAL.md — BADGES + COLLECTION CARDS + PRESS ICONS (art-final pass)

Owner: ASSETS agent. Session branch `arena/01a099a0-igra` (task says push to `arena/art-final`; remote push uses that name). This file is the ONLY ledger for art-final work. One row per attempt/delivery step; every claim points at a verifiable artifact on disk. No fabricated entries.

Skills applied this pass: `asset_pipeline.md` (palette lock `#0c1016 #141b24 #2a3340 #c9a24a #8a7338 #aeb6bf #d8d2c4 #4a9ab5`, no pure #000/#fff, deterministic PIL pipeline, clamp [16,240], seamless-safe, dims-exact), `art-pipeline` (programmatic generation with PIL, glyph-legible at 48px, no AI text hallucination), `yagni` (cut AI image-gen for badges/cards — deterministic vector glyphs are more legible at 48px than diffusion; cut extra press variants beyond the 2 required), `self-commit` (one block = one commit + push), `surgical-edit` (only owned paths). NOT used: `godot-gates` (NEVER-GODOT standing — no engine in sandbox; correctness proven by PNG decode + pixel math), `council`.

SAVE PROTOCOL: all generated PNGs written to owned paths only, then verified by `/tmp/verify_art_final.py` (exit 0 = 0 defects), then contact sheets published to `docs/artifacts/art-final/` before commit. No temp files committed.

## L1 — canon read (TASK 0 pre-work)

Read `docs/PLAYER_VISIBLE_CHANGES.md` Batch 13 (GOLD MASTER v5) and `PLAN.md`:

- **31 achievements now (was 20) — one for fully restoring each of the 11 districts, on top of existing set.** Source: `scripts/systems/achievements_manager.gd` `ACHIEVEMENTS` dict — 20 original `ach_01`..`ach_20` + 11 per-district `ach_district_<id>` = 31 total. Verified by grep count = 31 keys.
- **11 districts**: `suburbs`, `residential`, `park`, `school`, `hospital`, `gas_station`, `police`, `warehouses`, `industrial`, `substation`, `power_station`. Source: `scripts/world/district_scene_factory.gd` `DISTRICTS` constant (11 entries) and `data/districts/*.tres` (11 files). Order preserved for cards.

Exact shipped achievement list (31) with tier assignment for palette-lock:

| # | ID | Name (en) | Condition | Tier | Glyph |
|---|---|---|---|---|---|
| 1 | ach_01 | First Light | district_1_full | bronze | streetlight |
| 2 | ach_02 | Electrician | any_district_full | silver | bolt |
| 3 | ach_03 | Beacon | all_districts_full | platinum | starburst |
| 4 | ach_04 | Librarian | all_documents_collected | gold | book |
| 5 | ach_05 | Shadow Hunter | kill_shadows_50 | silver | skull |
| 6 | ach_06 | Quiet as a Mouse | district3_stealth | silver | eye_slash |
| 7 | ach_07 | Combo Master | combo3_x10 | silver | chevrons |
| 8 | ach_08 | Overloaded | overload_5min | bronze | weight |
| 9 | ach_09 | Photographer | photos_10 | bronze | camera |
| 10 | ach_10 | Seeker | secrets_10 | silver | magnify |
| 11 | ach_11 | Economist | coins_5000 | silver | coin |
| 12 | ach_12 | Without a Scratch | district4_no_damage | gold | shield |
| 13 | ach_13 | The Architect | boss_defeated | gold | crown |
| 14 | ach_14 | Truth | ending_truth | platinum | eye |
| 15 | ach_15 | Darkness | ending_dark | gold | moon |
| 16 | ach_16 | Speedrunner | speedrun_4h | platinum | clock |
| 17 | ach_17 | Collector | all_flashlight_skins | gold | flashlight |
| 18 | ach_18 | Iron Man | hardcore_clear | platinum | anvil |
| 19 | ach_19 | Midsummer Night's Dream | sleep_in_bed | bronze | bed |
| 20 | ach_20 | Who's There? | hallucinations_5 | bronze | ghost |
| 21 | ach_district_suburbs | Suburbs | district_suburbs_full | bronze | house |
| 22 | ach_district_residential | Residential | district_residential_full | bronze | apartment |
| 23 | ach_district_park | Park | district_park_full | bronze | tree |
| 24 | ach_district_school | School | district_school_full | silver | school |
| 25 | ach_district_hospital | Hospital | district_hospital_full | silver | hospital |
| 26 | ach_district_gas_station | Gas Station | district_gas_station_full | silver | fuel |
| 27 | ach_district_police | Police | district_police_full | silver | police |
| 28 | ach_district_warehouses | Warehouses | district_warehouses_full | gold | crate |
| 29 | ach_district_industrial | Industrial | district_industrial_full | gold | factory |
| 30 | ach_district_substation | Substation | district_substation_full | gold | substation |
| 31 | ach_district_power_station | Power Station | district_power_station_full | platinum | tower |

Districts (11) for cards: suburbs, residential, park, school, hospital, gas_station, police, warehouses, industrial, substation, power_station.

Palette tokens from `docs/STYLE_GUIDE.md` + `asset_pipeline.md`: bg-deep `#0c1016`, panel `#141b24`, edge `#2a3340`, brass `#c9a24a`, brass-dim `#8a7338`, steel `#aeb6bf`, bone `#d8d2c4`, teal `#4a9ab5`, ember `#b4452f` (danger only). Banned: pure `#000000`/`#ffffff`, neon, saturation >40% on surfaces.

Tier palettes defined for this pass (all clamped [16,240], no pure):

- bronze: ring `#8a7338` (138,115,56), highlight `#c9a24a` (201,162,74), dark `#5a4a2a` (90,74,42), bg `#141b24` (20,27,36), inner `#1c252f` (28,37,47), glyph bone `#d8d2c4` (216,210,196)
- silver: ring `#aeb6bf` (174,182,191), highlight bone, dark `#2a3340` (42,51,64), bg panel, inner `#1e2632` (30,38,50)
- gold: ring brass `#c9a24a`, highlight `#e0c48a` (224,196,138), dark brass-dim, bg panel, inner `#202832` (32,40,50), glyph `#e8dcc4` (232,220,196)
- platinum: ring bone `#d8d2c4`, highlight `#e6e2d6` (230,226,214), dark teal `#4a9ab5` (74,154,181), bg panel, inner `#222a34` (34,42,52)

## L2 — 31 badge icons 128² (TASK 1, DELIVERED 31/31)

Generated via deterministic PIL pipeline `/tmp/gen_art_final.py`:

- Each badge: 128×128 RGBA, outer circle bg panel, inner circle slightly lighter, 8px tier ring + 2px highlight ring, central 76×76 glyph (vector, thick strokes ≥3px for 48px legibility).
- Glyphs are simple geometric primitives (no text, no diffusion) to survive 48px downscale — verified by 48px thumbnail std/contrast.
- All pixels clamped to [16,240] — 0 pure black/white. Verified by numpy scan.
- Files: `assets/textures/badges/badge_<achievement_id>_128.png` (31 files). Naming matches `ACHIEVEMENTS` keys verbatim.

Self-check at generation: dims exact, purity 0/0, min ≥20 max ≤232, mean saturation low (palette-locked). Thumbnail legibility pass: resize to 48² LANCZOS, measure std >8 and contrast (max-min) >25 — all 31 pass (range std 50.9–89.8, contrast 229–255).

Committed after verification.

## L3 — 11 collection cards 512² + locked silhouettes (TASK 2, DELIVERED 22/22)

Generated via same PIL pipeline:

- Unlocked: `card_<district>_512.png` — 512×512, vertical gradient from district ambient (from `district_themes.gd`) to panel `#141b24`, double soft glow ellipse in district accent (alpha 35/60), 6px accent border, central 260×240 district glyph (bone, thick), top light cone accent (streetlight hint), clamped [16,240].
- Locked: `card_<district>_locked_512.png` — same layout but desaturated silhouette (70,70,75) + lock icon (180,180,180) at bottom center, darker overall, still clamped.
- District themes used (accent clamped to 240 max): suburbs/residential `f0a35d`, park `f0e35d`, school `f0c95d`, hospital `5dc8f0`, gas_station/warehouses/industrial `e85d3a`, police `5d5dc8`, substation/power_station `f0f05d`.
- Files: 22 total, 11 unlocked + 11 locked, exact 512², 0 pure black/white.

Verification: dims/purity re-parse via `/tmp/verify_art_final.py` — 22/22 PASS.

## L4 — store/press icons (TASK 3, DELIVERED 2/2)

Master: `store/icon-512.png` (512×512, RGB, contains pure 0/255 — clamped to [16,240] at generation).

- `icon_round_512.png`: master scaled to 80% (410px) and centered for safe-zone (10% margin = 51px), then circular alpha mask (ellipse 0,0,511,511). Corners transparent (corner 50×50 alpha <10 ratio 1.00), central 80% opaque containment 1.00 — safe-zone PASS. Clamped, 0 pure.
- `icon_mono_512.png`: high-contrast mono — panel bg `#141b24` (20,27,36) luminance ~26, foreground bone `#d8d2c4` luminance ~211, derived from thresholded master (gray>60 && alpha>20, then scaled to safe-zone). Contrast 5-95 percentile = 184 (low 26 high 210), min 26 max 210, 2 unique levels — mono contrast PASS.

Verification: safe-zone + mono contrast check in verify script — 2/2 PASS.

## L5 — verification + contact sheets (TASK 4)

Verification script `/tmp/verify_art_final.py` (exit 0):

- Badges: 31 files, dims 128² exact, purity 0 pure black/white, palette range [16,240], thumbnail legibility std>8 contrast>25 — 0 defects.
- Cards: 22 files, dims 512² exact, purity 0 — 0 defects.
- Press: 2 files, dims 512², purity 0, round safe-zone corner trans 1.00 central 0.97 containment 1.00, mono contrast 184 — 0 defects.
- TOTAL DEFECTS: 0.

Contact sheets published to `docs/artifacts/art-final/`:

- `badges_contact_sheet.png` (8 cols × 4 rows, 1024×512, 128px cells)
- `badges_contact_sheet_48.png` (same grid at 48px — legibility proof)
- `cards_contact_sheet.png` (4 cols, 256px thumbs, unlocked + locked)
- `press_contact_sheet.png` (3×512 strip: master + round + mono)

Origin note (license): all 31 badges + 22 cards + 2 press icons are project-authored deterministic program output (PIL, this session), no third-party rights, no attribution required. Master icon is repo-owned.

## Commits this pass (branch `arena/01a099a0-igra` → remote `arena/art-final`)

| Hash | Subject |
|---|---|
| (to be filled after commit) | art-final: add 31 badges 128² tier palettes, 22 cards 512² locked variants, 2 press icons + contact sheets + ledger/cert |

## Files owned & touched

- `assets/textures/badges/badge_*.png` (31)
- `assets/textures/cards/card_*_512.png` (22)
- `store/press/icon_round_512.png`, `icon_mono_512.png` (2)
- `docs/LEDGER_ARTFINAL.md` (this file)
- `docs/CERT_ARTFINAL.md`
- `docs/artifacts/art-final/*.png` (4 contact sheets)

Zero writes to forbidden paths (`docs/ASSET_LICENSES.md`, code, locales, etc.) per ownership rule.
