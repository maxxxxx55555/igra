# Store gallery — final engine captures (11 files, 1920×1080)

These are engine frames captured from the final 2026-11-22 visual tree, not painted
marketing art. The set is **8 EN gallery shots + 3 touch-HUD phone shots**, all
1920×1080 PNG. It replaces the earlier painted/composed set that was never valid for
the Play screenshot slots.

Capture source: `scripts/tools/_release_store_shots_runner.gd` (windowed, final tree).
Shot framing and district context: `store/screenshot-plan-detailed.md` and
`store/screens_spec/shotlist.json`.

Upload order (Play Console):

1. `shot01_light_vs_dark_1920x1080_en.png`
2. `shot02_district_boundary_1920x1080_en.png`
3. `shot05_restored_forecourt_1920x1080_en.png`
4. `shot07_last_streetlight_1920x1080_en.png`
5. `shot08_city_map_1920x1080_en.png`
6. `shot_p1_touch_first_light_1920x1080_en.png`
7. `shot_p2_touch_crouch_1920x1080_en.png`
8. `shot_p3_touch_interact_1920x1080_en.png`

The remaining three files (`shot03_stealth_horror`, `shot04_keeper_lore`,
`shot06_mystery_inside`) are captured and available as extra gallery candidates; the
eight-slot order above is the current Play selection.

| File | Plan shot | District · stage | HUD / Trailer Mode | LUT |
|---|---|---|---|---|
| `shot01_light_vs_dark_1920x1080_en.png` | §3 Shot 1 (⭐ hook) | suburbs FULL, Maple Row reverse | HUD off (Trailer Mode ON) | suburbs |
| `shot02_district_boundary_1920x1080_en.png` | §3 Shot 2 | residential FULL ↔ park DARK, `z_exit_east` | HUD off | residential |
| `shot03_stealth_horror_1920x1080_en.png` | §3 Shot 3 | residential courtyard, monster staged 6 m out | HUD off | residential |
| `shot04_keeper_lore_1920x1080_en.png` | §3 Shot 4 | park FULL, keeper-shed read | HUD off | park |
| `shot05_restored_forecourt_1920x1080_en.png` | §3 Shot 5 | gas_station FULL, `z_pump_island` | HUD off | gas_station |
| `shot06_mystery_inside_1920x1080_en.png` | §3 Shot 6 | industrial FULL, workshop read | HUD off | industrial |
| `shot07_last_streetlight_1920x1080_en.png` | §3 Shot 7 (⭐ money) | power_station FULL, Architect staged | HUD off | power_station |
| `shot08_city_map_1920x1080_en.png` | §3 Shot 8 | all 11 districts FULL (city map overlay) | Map open | none (UI) |
| `shot_p1_touch_first_light_1920x1080_en.png` | §7 P1 | suburbs first-light, touch HUD visible | HUD **ON** | suburbs |
| `shot_p2_touch_crouch_1920x1080_en.png` | §7 P2 | residential courtyard, stealth read | HUD **ON** | residential |
| `shot_p3_touch_interact_1920x1080_en.png` | §7 P3 | residential power-switch, interact pulse | HUD **ON** | residential |

Touch-HUD shots are native 1920×1080 frames with the real touch controls. No overlay
text or arrows are burned in; Play applies its own captions.

Spoiler ceiling respected (`VISUAL_AUDIO_SPEC` §4 rule 5): Act I districts plus the lit
power-station finale; no ending text, no Architect identity reveal, no death screen.
