# Correction log

Earlier claims later contradicted by evidence. Newest first. Each row: what was claimed, what is
actually true, and the commit that establishes it.

| # | Old claim (where) | New fact | Commit |
|---|---|---|---|
| 1 | R0 magenta rendering corruption "fixed" by `scaling_3d/scale` 0.8→1.0, world magenta 2.46%→0.09% (RUN_STATE, `24116c4`; evidence frames `docs/stills/evidence/r0_after_*.png`) | Those frames were clean because the world textures **never loaded**: the committed `.import` files pointed at cache files this Godot build does not produce. With textures actually loaded the world is 13% magenta with banding rings. Real cause: the 11 district LUTs were imported as `CompressedTexture2D`, which `Environment.adjustment_color_correction` samples as a 1D gradient. Imported as Texture3D: 0.01–0.30% hue-magenta across 10 windowed frames. Lossless and S3TC were A/B'd and ruled out. | `bafb740` |
| 2 | "Stale headless import cache" as a recurring environment hazard, fixed by a windowed reimport (RUN_STATE Session 10, `fa5fee4`) | The recurring breakage came from **reverting `.import` files after the reimport**, which re-pointed them at nonexistent cache files. The fix is to commit the `.import` files Godot 4.7 actually writes. | `37581d7` |
| 3 | C06 graphics-tier fog MET (`f738e99`, TZ_COMPLIANCE) | The `SettingsManager` fog write was overwritten by `world_env_setup.gd`, and the windowed verifier measured 0.013 on every tier. Rebuilt on `visual_quality.tres` as the single source. | `2547fff` |
| 4 | V05 shadow atlas 2048 causes the magenta (said in-session on 2026-09-25 after one A/B, never committed as a decision) | Confounded: that A/B also swapped the texture import state. Re-run with import state held constant: 2048 = 0.03%, same as 1024. V05 stays 2048. | `bafb740` (method), this log |
| 5 | FUNCTION_MATRIX X22 "death screen doesn't display when boot is bypassed" = game bug | Test bug. Phase 8 read the legacy `Screens` node, whose autoload is commented out. The live death screen is opened by `UIManager`. | `0d3d533` |
| 6 | FUNCTION_MATRIX X20 "park-travel inf-position softlock" | `ppos=(inf…)` is the heartbeat sentinel for "no valid player", and the game was in PAUSED, which only a real Escape key reaches. The bot had no PAUSED branch. Harness fixed and A/B-proven; the keypress trigger is inferred, not proven. | `0d3d533` |
| 7 | FUNCTION_MATRIX footer: 58 WORKS / 43 UNTESTED | A recount of the rows gave 61 / 40. The footer was stale. The matrix now has 0 UNTESTED rows. | `0d3d533` |
| 8 | GOLD MASTER suite "exits 124 with no FAIL lines when clean" (C3 close-out) | Phases P2l, P2m and P3 fail intermittently on identical code (0 and 3 fails on repeated runs of the same HEAD). Root-caused and fixed: P2l/P3 were victims of the progress-signature bug (`ac877a5`); P2m landed in the gate scene's PLAYING->MENU window (bounded PLAYING wait, `c00f118`). Suite now `fails=0` on 3 consecutive runs. | `ac877a5`, `c00f118` |
| 9 | TZ_COMPLIANCE_AUDIT A04: SFX over the 50 MB cap | The `ambience/` folder holds the five adaptive **music** layers GDD A02 names. Counted by role, not by folder, both caps hold. | `4bb5772` |
| 10 | Commit `d06fe48` message says "item 6" | It closed SLOP item 7 (the disabled-button StyleBox). The message is cosmetic, and the history is left as-is. | this log |
| 11 | Commit `ad051fc` message: tz_verify frames "all PASS visual_truth_gate" | False: V02_energy_ball failed at 0.59% hue-magenta (the ember light spill pushed pink by the LUT). Fixed with a brass light. | `ae410b9` |
| 12 | Commit `ae410b9` message: the one half-res FAIL is "C06 ultra tier" | It is `S03_noise_vignette.png` (0.66%): the saturation-outlier sub-detector counting the saturated ember edge vignette. | this log |
| 13 | TZ_COMPLIANCE P01 "MET-STATIC" (drawcall_estimate PASS) | Real GPU, windowed `perf_check_scene`: D1 suburbs **246** draw calls. The D11 < 350 budget passes; D1 < 200 does not. | this log |
| 14 | "S01 hit/dodge noise MET" (session notes before the IRON RULE bisect) | Not shipped: bot 0/3 with S01 vs 2/3 without. Recorded as DR-3 in TZ_DECISIONS. | `c00f118` |
