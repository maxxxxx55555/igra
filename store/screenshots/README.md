# Store art — LAST STREETLIGHT (8 painted or composed pictures, 1920×1080: NOT screenshots)

**Do not upload these as the screenshots of a store page.** Five are AI paintings of a street with a post pass (`docs/ASSET_LICENSES.md`), shot08 is a programmatic redraw of a city list
and three put the touch sprites over an AI background: none is a frame the engine drew, and shot02 shows a crossing between two districts that the game does not have (the
city map travels between districts). The store asks for screenshots that show the app as it is. **The screenshots to upload are the engine frames of `docs/stills/store/`**
(each named with the commit and the UTC time it was shot at; `store/PRESS_KIT.md` lists them). The pictures below are marketing art, for a place where a painting is fine.

Owner: CONTENT+ASSETS agent (visual pass). Eight pictures (art, not screenshots),
1920×1080, 24-bit PNG (each ≤ 2.1 MB), composed per `store/screenshot-plan-detailed.md`.
Every frame is palette-pure (0 pure `#000000` / `#ffffff` texels, channels clamped to
[16,240] for the environment shots) and graded with the district LUT from
`assets/textures/luts/` (luma-mix strength 0.6: district tint in the shadows, warm
practicals preserved), then bloom + vignette. No overlay text/arrows.

Upload order: none; the screenshot slots take the engine frames of `docs/stills/store/`.

| File | Plan shot | District · stage | HUD / Trailer Mode | LUT |
|---|---|---|---|---|
| `shot01_light_vs_dark_1920x1080_en.png` | §3 Shot 1 (⭐ hook) | suburbs FULL, Maple Row reverse | HUD off (Trailer Mode ON) | suburbs |
| `shot02_district_boundary_1920x1080_en.png` | §3 Shot 2 | residential FULL ↔ park DARK, `z_exit_east` | HUD off | residential |
| `shot05_restored_forecourt_1920x1080_en.png` | §3 Shot 5 | gas_station FULL, `z_pump_island` | HUD off | gas_station |
| `shot07_last_streetlight_1920x1080_en.png` | §3 Shot 7 (⭐ money) | power_station FULL, `z_cooling_towers`→`z_station_gate` | HUD off | power_station |
| `shot08_city_map_1920x1080_en.png` | §3 Shot 8 | all 11 districts FULL (city map overlay) | Map open (this shot *is* UI) | none (UI, palette-clamped) |
| `shot_p1_touch_first_light_1920x1080_en.png` | §7 P1 | suburbs first-light, touch HUD visible | HUD **ON** (Trailer Mode OFF) | suburbs |
| `shot_p2_touch_crouch_1920x1080_en.png` | §7 P2 | residential courtyard, crouched stealth read | HUD **ON** | residential |
| `shot_p3_touch_interact_1920x1080_en.png` | §7 P3 | residential power-switch, interact pulse | HUD **ON** | residential |

Touch-HUD shots are the 20:9 phone frame (1920×864 content) centered in the 1920×1080
canvas and letterboxed with flat `#0c1016` bars (108 px top + bottom) — pad, never crop,
per §7. The HUD composites the repo's real touch sprites
(`assets/textures/touch/touch_joy_base_256.png`, `_knob`, `touch_interact_128.png`,
`touch_back_128.png`, `touch_pause_128.png`) plus programmatic HP / stamina / battery bars
in the shipped palette (`#d8d2c4` / `#5f8a4e` / `#c9a24a`).

Spoiler ceiling respected (VISUAL_AUDIO_SPEC §4 rule 5): Act I districts + the lit
power_station finale only; no ending text, no Architect reveal, no death screen.

RU companion set not produced this pass (the plan allows EN-only; `store/listing.md` +
`tools/gen_store_listing_locales.py` cover other locales — CODE merges).
