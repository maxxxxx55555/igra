# Beauty pass rc16 (O3): what was kept, what was not done, and the frames behind it

Method: the A-beauty agent (zone Z-visual, no engine) read the eight BEFORE frames of `e4bb4df` (`docs/stills/polish/*_before_e4bb4df_*.png`), the canon (`docs/STYLE_GUIDE.md`,
`docs/PRODUCTION_BIBLE.md`, `docs/GDD.md`) and the engine sources, and committed one item per commit; the orchestrator merged it, applied three of its cross-zone requests,
captured the eight AFTER frames once (`c3e79e5`, launch 19), read each one once and measured them (`tools/qa_sim/frame_stats.py`, raw output
`docs/artifacts/rc16/proofs/frame_stats_c3e79e5.out`). Every kept item except X1 (the LUT image, shown by the beauty frames only) has a closeout check that fails on the code before it (`scripts/tools/rc16/beauty_checks.gd`, `scripts/tools/rc16/uifx_checks.gd`).

## Kept (6)

| id | change | measured effect | frames read |
|---|---|---|---|
| O3.1 | the HUD grain pass reads the screen with `filter_linear`, not a mipmap filter (`assets/shaders/grain_overlay.gdshader:12`) | pixels identical (the sampler is read 1:1 at `SCREEN_UV`); the engine builds a blur chain for a mipmap filter on a screen sampler; saving not measured | none visible, by design |
| O3.2 | the damage vignette beat runs on the age of the hit (`age` in `assets/shaders/damage_vignette.gdshader:24`), so each hit starts on the peak | corner alpha at a hit: 0.10 to 1.00 before (46.5 % of hits under 0.5, shader formula), 1.00 now | frame 05 after: the ember red is on all four edges 0.06 s after the hit; frame 05 before shows none |
| O3.3 | the HUD grain hash without the 10 px repeat (`assets/shaders/grain_overlay.gdshader:19`) | strongest bin of the 2D spectrum over the mean bin on the sky patch, same staged scene: frame 01 104.7 to 38.1, frame 02 103.8 to 26.8, frame 03 139.4 to 30.9 (white noise reads about 9) | frames 01 to 03 after: fine noise, no mosaic |
| X1 | `assets/textures/luts/lut_suburbs.png` and `lut_residential.png` (the same file): the tint taken out of the highlights, a mild warm gain, the darks unchanged | white (255,255,255) came out (216,239,208) hue 105, now (240,232,213) hue 42; brass (200,162,74) (166,158,87) to (196,153,65); mean hue of the lit pixels, frames 01 to 05: 77, 99, 98, 90, 92 to 48, 43, 47, 41, 39 degrees (brass is 42) | frames 01, 02, 03 after: the light pools are cream and brass, not green |
| X2 | `MotionBlurCopy` (`BackBufferCopy`) between the blur and the chroma layers, on only while the blur is (`scripts/post_process_overlay.gd`) | with it the Ultra sprint blur is on screen | frame 06 after: radial streaks at all four edges; the HUD hint panel is smeared too (the overlay layer is above the HUD) |
| X3 | the post-process grain hash does not fade with uptime (`scripts/post_process_overlay.gd`): the old one multiplied a growing time shift by 234.34 and 435.345 and was constant after about 20 minutes (the agent's float32 model: healthy for about the first 30 s, 36 distinct values at 200 s, constant 0 from about 1400 s) | the model, not a run: the frames are inside the first minute | all frames: grain present |

Also fixed during the pass (not beauty, same package): the toast lives 3 s (TO1), no day in the menu background (MENUBG1), the attack button greys under 5 stamina (ATK1), the hover tween meta is read only when it exists (`08af752`; the engine error about the missing `hover_tween` meta is in six logs of launches 2, 3, 4, 5 and 7 and in none of the six closeout logs after that commit, `f5_hover_tween.out`).

## Not done

| item | reason |
|---|---|
| X4 the HUD builds a second grain and vignette over the overlay's (`scripts/ui/hud_3d.gd:143`, `:326`-`:347`) | taste: the picture reads thinner without it; would also drop BEAUTY1 and BEAUTY3; open |
| X5 the district LUT is switched off 0.5 s after every graphics-tier change and every `WorldEnvironment` entering the tree (`scripts/systems/settings_manager.gd:441`-`:475`, `:535`, `:548`): frames 06 and 07 are LUT-off (hue 35 and 45), frames 01 to 05 are LUT-on | the fix touches the contrast and saturation the tier sets (1.03 / 0.92 against 1.1 / 1.05) and the high-contrast toggle; no frame decides it; open, patch in the agent's report: `adjustment_enabled = high_contrast or env.adjustment_color_correction != null` and keep the tier's contrast and saturation |
| X6 glow stays on at the Low tier (`assets/config/visual_quality.tres:9`, `scripts/world_env_setup.gd:272`) | the Low preset says `glow_enabled: true`; whether that is meant is a design decision |
| X7 the flashlight shadow is not tier-gated (`scripts/player/player_3d.gd:288-290`; `SettingsManager.set_shadow_quality` only touches the group `shadow_casters`) | desktop Low only (mobile already turns it off); open |
| X8 the shop's buy buttons overlap the next row and the last row is cut by the scroll area (found in the S8 frame read; the old frame `A06_shop_after_bca7d33_20261007T234825Z.jpg` was replaced) | **Done in the RC16 FINISH pass (F1)**: a shop card is a PanelContainer with a VBoxContainer, so its height follows its content (`var card_item := PanelContainer.new()`, `scripts/ui/screens.gd:970`); check SHOP1 failed before and passes in 39 of 39 cases; frame `A06_shop_after_74f710b_20261008T091547Z.png`. The Arabic shop has a separate open defect (`docs/KNOWN_ISSUES.md`) |
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
the menu without the day palette, the mirrored Arabic and the Japanese settings screens. They held the two rc15 defects listed above (X8 and the skill tree Close, closed in the RC16 FINISH pass, `docs/KNOWN_ISSUES.md`); the two frames of those screens were removed and re-shot at the fixed code as `docs/stills/rc16_f1/` (the shop in Russian and in Arabic, the skill tree in Russian, each read once: the Russian shop and the skill tree show the fixes, the Arabic shop shows its content outside the panel). `S_credits_after_bca7d33_20261007T235656Z.jpg` is byte-identical to the rc15 frame of the same name: the credits screen is static, the run rewrote the file at 23:56:56Z (`docs/artifacts/rc16/proofs/playthrough_frames_utc.out`), and AF3 F6 compares only inside a set, so the bytes alone cannot show it was redrawn.

## Shipping pass (Session 21): three items tried, one kept

Method: one windowed launch with a sweep (ledger row 70, `s21_sweep_cdf2035`: five tonemap pairs at three states and three menu tints, measured with PIL and read), one launch for the AFTER frames of the kept items (row 71, `s21_b1_2d502ee`), the final six frames (rows 75 and 80), each frame read once. BEFORE is the release set of `18a2a2a` (`docs/stills/release/`); AFTER is `docs/stills/shipping/` (AF3 names; `docs/stills/shipping/batch1/` holds the three frames of the batch and `docs/stills/shipping/halo_defect/` the record of V2).

| id | change | measured | frames read | verdict |
|---|---|---|---|---|
| V1 | the menu hero art multiplied by bone over near-white, `HERO_TINT` (`scripts/ui/main_menu.gd:84`) | the share of the menu frame at 225 or more of any channel 8.80 % to 0.06 % | the lamp glow and ground pool read bone-cream, the brass cone and the title keep their weight; the stronger tint (0.88, 0.85, 0.78) greys the cone | kept |
| V2 | a brass glow around lit streetlights, one additive camera-facing quad per lamp in a MultiMesh, Medium tier and up (`2d502ee`) | 48 lamps in the spawn district, one more draw per district | the lit street's lamps read as lamps (white specks before) in launch 71; **in launch 75 (frame 04) about seven flat pale squares, up to 250 px wide in the pose probe, centred on lamp heads that were a few metres from the camera** | **reverted** (`7734ade`, CORRECTION_LOG 201) |
| V3 | `tonemap_white` and `tonemap_exposure` pairs (2:1.0, 3:1.1, 4:1.25, 6:1.4) against 1:1.0 | pixels with a channel at 240 or more: night 1.12 % to 0.08-0.11 %, day 2.11 % to 1.14-1.55 %, mean luma within 3 % | the frames look the same: the flashlight's energy 24 (`scenes/player/player_3d.tscn:180`) saturates all three channels, so the lit road stays a cream slab at any white point up to 6 | not kept, not applied |

V2, what is known: the squares are the glow's own quads (hidden with the glow, `halo_pose_b_hidden`), in the ring probe (launch 76) the frame with lamps at 2.6, 4.1 and 5.3 m shows them and the frames with the nearest lamp at 5.9 m or more show none (`halo_ring_d05`, `halo_ring_d08`), and the fixed pose gave the same square in all three runs that used it (launches 77, 78 and 79); they do not change with the shader's `peak` or `near_fade` (launch 78), so the fragment behaves as if the shader's formula were not in effect for those quads. Not known: why. A debug shader set at run time (launch 79) was answered by the engine's fallback, not by its output, and the diagnosis stopped there (the launch budget). A retry would start from `git show 2d502ee` and one question: does the glow draw the same square as a `StandardMaterial3D` (unshaded, billboard, additive, distance fade)? The look of the street in the frames where it worked (`docs/stills/shipping/batch1/lamp-halo-crop_after_2d502ee_20261011T192342Z.png`) is the reason to retry.

Left as it is: the white capsule of the staged combat frame is the 0.1 s hit flash of a brass-albedo monster 3 m in front of the flashlight (a flash, not a defect; the frames after repeated hits show the brass egg); the skill tree's small cards and empty screen, the inventory's empty field and the settings rows are layout work with 13-locale overflow risk, outside a closing pass. UNVERIFIABLE-HERE: V1 on a phone GPU (`docs/UNVERIFIABLE_HERE.md` U12).

## HUD pass (Session 22): two batches tried, two kept, none reverted

Plan and outcome row by row: `docs/HUD_PLAN.md`. Method: one windowed launch per batch with the frames runner (`TLS_FRAMES_OUT`, plus `TLS_HUD_DUMP`, a list of every
visible control with its rectangle and alpha), the same five states each time (calm, hurt, interact prompt, combat, touch layout at 1600 x 740 with touch emulated),
BEFORE and AFTER read side by side, the AF3 name on every frame.

| Batch | Head | Launch row | Items | Read in the frames | Verdict |
|---|---|---|---|---|---|
| BEFORE | `8874bb9` | 84 | none | five rows always on, two maps one inside the other, RADAR over the ring, a MELEE caption, an emoji map button, the objective list off screen, the touch cluster overlapping | the baseline |
| 1, the quiet corner | `51e2265` | 85 | contextual rows on one grid with the battery as segments; one map and touch-only buttons; the objective list on screen | the corner shows the battery and, in the dark, the visibility bar; one radar ring; the objectives are readable; a gap between the two rows (the order was changed in batch 2) | kept |
| 2, in play | `ccf61ee` | 86 | the combat HUD holds 5 s; prompt and notice fade; the touch cluster re-anchored and see-through, the LOG toggle dim; the rows regrouped | no crosshair and no MELEE at rest, the crosshair back on an enemy in the aim; the health row under the visibility bar when hurt; the right cluster clear of itself, dim at rest | kept |

Reverted: nothing. One defect of my own was found in the log of batch 1 and fixed in batch 2: `hud_fade.gd` asked for a meta key that did not exist (35 engine errors, no
effect on the frames). The boss frame's red vignette is in the BEFORE frame and in the frames of `2e018d3` too: it is not the HUD pass.

Decisions (mine, recorded so they can be undone): the city minimap is off by default (the radar is the one map; Settings turns the minimap on); the objective list shows for
8 s on a change instead of staying (it was never on screen before; by code it does not show at the very start of a first run, KNOWN_ISSUES); the touch controls rest at 0.55 (`_TOUCH_REST`), which is the figure to raise if
they read too dim on a phone (`docs/UNVERIFIABLE_HERE.md` U13).
