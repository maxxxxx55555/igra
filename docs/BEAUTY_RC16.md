# Beauty pass rc16 (O3): what was kept, what was not done, and the frames behind it

Method: the A-beauty agent (zone Z-visual, no engine) read the eight BEFORE frames of `e4bb4df` (`docs/stills/polish/*_before_e4bb4df_*.png`), the canon (`docs/STYLE_GUIDE.md`,
`docs/PRODUCTION_BIBLE.md`, `docs/GDD.md`) and the engine sources, and committed one item per commit; the orchestrator merged it, applied three of its cross-zone requests,
captured the eight AFTER frames once (`c3e79e5`, launch 19), read each one once and measured them (`tools/qa_sim/frame_stats.py`, raw output
`docs/artifacts/rc16/proofs/frame_stats_c3e79e5.out`). Every kept item has a closeout check that fails on the code before it (`scripts/tools/rc16/beauty_checks.gd`, `scripts/tools/rc16/uifx_checks.gd`).

## Kept (6)

| id | change | measured effect | frames read |
|---|---|---|---|
| O3.1 | the HUD grain pass reads the screen with `filter_linear`, not a mipmap filter (`assets/shaders/grain_overlay.gdshader:12`) | pixels identical (the sampler is read 1:1 at `SCREEN_UV`); the engine builds a blur chain for a mipmap filter on a screen sampler; saving not measured | none visible, by design |
| O3.2 | the damage vignette beat runs on the age of the hit (`age` in `assets/shaders/damage_vignette.gdshader:24`), so each hit starts on the peak | corner alpha at a hit: 0.10 to 1.00 before (46.5 % of hits under 0.5, shader formula), 1.00 now | frame 05 after: the ember red is on all four edges 0.06 s after the hit; frame 05 before shows none |
| O3.3 | the HUD grain hash without the 10 px repeat (`assets/shaders/grain_overlay.gdshader:19`) | strongest bin of the 2D spectrum over the mean bin on the sky patch, same staged scene: frame 01 104.7 to 38.1, frame 02 103.8 to 26.8, frame 03 139.4 to 30.9 (white noise reads about 9) | frames 01 to 03 after: fine noise, no mosaic |
| X1 | `assets/textures/luts/lut_suburbs.png` and `lut_residential.png` (the same file): the tint taken out of the highlights, a mild warm gain, the darks unchanged | white (255,255,255) came out (216,239,208) hue 105, now (240,232,213) hue 42; brass (200,162,74) (166,158,87) to (196,153,65); mean hue of the lit pixels, frames 01 to 05: 77, 99, 98, 90, 92 to 48, 43, 47, 41, 39 degrees (brass is 42) | frames 01, 02, 03 after: the light pools are cream and brass, not green |
| X2 | `MotionBlurCopy` (`BackBufferCopy`) between the blur and the chroma layers, on only while the blur is (`scripts/post_process_overlay.gd`) | with it the Ultra sprint blur is on screen | frame 06 after: radial streaks at all four edges; the HUD hint panel is smeared too (the overlay layer is above the HUD) |
| X3 | the post-process grain hash does not fade with uptime (`scripts/post_process_overlay.gd`): the old one multiplied a growing time shift by 234.34 and 435.345 and was constant after about 20 minutes (the agent's float32 model: healthy for about the first 30 s, 36 distinct values at 200 s, constant 0 from about 1400 s) | the model, not a run: the frames are inside the first minute | all frames: grain present |

Also fixed during the pass (not beauty, same package): the toast lives 3 s (TO1), no day in the menu background (MENUBG1), the attack button greys under 5 stamina (ATK1), the hover tween meta is read only when it exists.

## Not done

| item | reason |
|---|---|
| X4 the HUD builds a second grain and vignette over the overlay's (`scripts/ui/hud_3d.gd:143`, `:326`-`:347`) | taste: the picture reads thinner without it; would also drop BEAUTY1 and BEAUTY3; open |
| X5 the district LUT is switched off 0.5 s after every graphics-tier change and every `WorldEnvironment` entering the tree (`scripts/systems/settings_manager.gd:433`-`:442`, `:515`): frames 06 and 07 are LUT-off (hue 35 and 45), frames 01 to 05 are LUT-on | the fix touches the contrast and saturation the tier sets (1.03 / 0.92 against 1.1 / 1.05) and the high-contrast toggle; no frame decides it; open, patch in the agent's report: `adjustment_enabled = high_contrast or env.adjustment_color_correction != null` and keep the tier's contrast and saturation |
| X6 glow stays on at the Low tier (`assets/config/visual_quality.tres:9`, `scripts/world_env_setup.gd:259`) | the Low preset says `glow_enabled: true`; whether that is meant is a design decision |
| X7 the flashlight shadow is not tier-gated (`scripts/player/player_3d.gd:292`-`:294`; `SettingsManager.set_shadow_quality` only touches the group `shadow_casters`) | desktop Low only (mobile already turns it off); open |
| X8 the shop's buy buttons overlap the next row and the last row is cut by the scroll area (`scripts/ui/screens.gd:994`, `:926`; frame `A06_shop_after_bca7d33_20261007T234825Z.jpg`) | found in the S8 frame read and identical in the rc15 frame; fixing it changes a runtime path after the stamped frames (AF3 F4) with no launch to spare; `docs/KNOWN_ISSUES.md`; open |
| district ambient, sky and fog colours (`scripts/world/district_themes.gd`) | per-district tints are canon (`docs/VISUAL_AUDIO_SPEC.md`); they light only surfaces no lamp reaches |
| `scripts/world/district_grading.gd` constants | inert: its `_env` is never set (`scripts/world/world_bootstrap.gd`); the live environment owner is `scripts/world_env_setup.gd` |
| unreferenced `assets/env/*.tres` and shaders (`contact_shadow`, `foliage_sway`, `height_fog_card`, `streetlight_flicker`, `wet_asphalt`, `menu_parallax`) | referenced nowhere; no frame can change; two of them add a screen copy or overdraw |
| particles | `SettingsManager` already scales every `GPUParticles3D` by tier; pooled bursts live 0.6 s at most; rain, dust and strobe are never instanced |
| frame 07 "steam street" | no node is in the group `steam_vent`: there is no steam to polish; the frame shows the lamps |

Frames not comparable between before and after: in the combat states 04 to 06 the staged monster stands close in front of the camera in the after frames and farther away in the before frames, so their luma and grain numbers are not a like-for-like change.

## The final frames and the play-through frames (S8)

Six final frames from launch 15 (`tools/qa_sim/guarded_windowed res://scenes/tools/final_frames_scene.tscn 900`, log `docs/artifacts/rc16/proofs/s8_final_frames_41afa7e.attach.final_frames_scene.log`, `[final] DONE frames=6`),
stamped into `docs/stills/rc16_final/` under their AF3 names (`41afa7e`, capture UTC 20261008T002148Z to 002202Z), each read once:
01 the menu (English: Continue, Play, Settings, Difficulty, Credits, Quit, the daily card; the brass cone without the day palette); 02 a lit district with the level-up and coin toasts; 03 the same district dark ("You wake up. The city has gone dark.");
04 combat (the crawler at point-blank, white from the hit flash and the glow, a hit number and a crit mark, the name bar reads "Crawler" in a 4x crop); 05 the boss (the dark monolith in the centre, an ember hit vignette over the whole frame and a "Crawler" name bar at the top; the runner heals the player
before it stages 05 (`scripts/tools/_final_frames_runner.gd:176`), so the vignette is the hit feedback and not the low-health tint, and which hit landed was not traced); 06 victory with the "Set up New Game+" action ("Districts restored: 11/11").
The rc15 frames of the same names show no vignette in 05 and no monster in 04; the staged camera differs, so the pairs are not like-for-like.

The 26 play-through frames kept in `docs/stills/rc16_playthrough/` (read once each, observations in `docs/RUN_STATE.md`, S8 frame read) show the rc16 changes in the real game: the quick-slot hint that says a right-click resets the slot, the floating damage number with the ember vignette and the chroma pulse at a hit,
the menu without the day palette, the mirrored Arabic and the Japanese settings screens. They also hold the two rc15 defects listed above (X8 and the skill tree Close, `docs/KNOWN_ISSUES.md`).
