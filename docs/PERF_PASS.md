# Perf pass: static consolidation at `ce782f8`, re-measured at rc14

Every performance number that can be sourced without running Godot, next to its budget. Budgets
come from GDD §15 (`docs/GDD.md:385-389`, mobile) unless noted.

Tags:
- **STATIC-ESTIMATE:** computed from the repo by the cloud audit (script or file scan).
- **CONFIG:** a setting's value, read from the repo.
- **NEEDS-GODOT-RECONFIRM:** only a windowed or on-device run can settle it. The last measured value
  is given if one exists.

## 0a. Session 22 windowed re-measure (Local, 2026-10-12)

`tools/qa_sim/guarded_windowed res://scenes/tools/perf_check_scene.tscn 300` and the audio scene, one ledger row (89, `s22_windowed_gates`, head `700e1ed`, runtime of `ccf61ee`),
windowed (`--windowed`; the perf log does not record the window size, and the frame dumps of the same day show a 1965x1080 canvas), the same iGPU as below, Master muted. Raw: `docs/artifacts/rc16/proofs/s22_windowed_gates.attach.perf_check_scene.log`.

| District | Draw calls | Primitives | Objects | Frame p95 | GPU mean | Process mean |
|---|---|---|---|---|---|---|
| D1 suburbs spawn | 142 (< 200 OK) | 47,281 | 407 | 28.79 ms | 15.37 ms | 29.99 ms |
| D11 power_station | 129 (< 350 OK) | 48,833 | 275 | 23.61 ms | 16.42 ms | 25.26 ms |

Texture memory 128.3 MiB, video memory 155.8 MiB. The probe's own breakdown of the 142 suburbs calls: `Main3D/HUD` 82, `Main3D/WorldRuntime` 27, `Main3D/MultiplayerManager` 13 (the
calls saved by hiding each node): the HUD is more than half of the draw calls and the total is under the budget; whether the pass changed the HUD's share is not known, because no windowed reading of the tree before it exists (Session 21 did not run the windowed gates, CORRECTION_LOG 203). These numbers are not comparable one to one with
section 0 (the primitive count there is 1.34 M against 47 K here; what changed it is not traced in this pass); the budget lines are the claim. The audio gate in the same
row: Music bus peak -10.1 dB, ceiling -1.5 dB, `PASS overall` on the first run (no second run was needed; CORRECTION_LOG 114).

## 0. rc14 windowed re-measure (Local, 2026-09-27)

`tools/qa_sim/guarded_windowed res://scenes/tools/perf_check_scene.tscn`, 4 runs, window 1965x1080,
AMD Radeon integrated GPU (OpenGL 3.3, `gl_compatibility`), Master muted (QA runs are silent).
The camera now follows the player: every D1 number before rc14 was taken from (0, 1.7, 0), where
ScreenShake pinned the FPS camera (CORRECTION_LOG 46), so they measured a view no player sees.

| District | Draw calls | Primitives | Objects | Frame p95 | GPU mean | Render CPU | Frame process |
|---|---|---|---|---|---|---|---|
| D1 suburbs spawn | 168-170 (< 200 OK) | 1.34 M | 389-391 | 33.3 / 34.2 ms; 79.9 / 90.8 ms in the 2 runs taken under background load | 20.2-23.7 ms | 0.9-1.0 ms | 32.0-34.8 ms |
| D11 power_station | 175-186 (< 350 OK) | 1.34 M | 410 | 40.3 / 40.4 ms; 40.1 / 52.7 ms under load | 23.4-26.4 ms | 1.1-1.2 ms | 40.2-44.3 ms |

Texture memory 138.9-144.7 MiB, video memory 160.5-166.3 MiB (desktop BPTC). This iGPU is
GPU-bound at about 30-40 fps at 1080p; primitives stay about 27x over the GDD's 50K per district.

**rc14 final, re-run on the sign-off tree `1fc90f1` (2026-10-01, same probe, windowed, muted):** D1 **175** draw calls, 1.338 M primitives,
392 objects, frame p95 **28.8 ms**; D11 **165** draw calls, 1.330 M primitives, 398 objects, p95 **30.0 ms**; texture
memory 144.7 MiB, video memory 168.3 MiB, `DONE fails=0`. (The same probe right after the beauty pass, before the loot and
i18n work: D1 178, D11 173, p95 24.4 / 25.8 ms, 144.8 / 168.5 MiB; the p95 spread between runs is machine load.) The skyline (`skyline.gd`: two MultiMesh draws and one ground plane) and
the stage-lit windows cost about 8-10 draw calls and no measurable frame time; the lower p95 than in the table above
is the quiet machine, not the change.

## 1. Numbers

| # | Metric | Budget | Value | Source | Tag |
|---|---|---|---|---|---|
| 1 | D1 draw calls | < 200 | **175** after the skyline, sign-off run (178 right after the beauty pass, 168-170 before it; rc14, windowed runs, camera at the player). The old 246 (C7) / 253 (rc11) were taken from the pinned camera at (0, 1.7, 0) | perf probe (§0) | MEASURED rc14, OK |
| 2 | D1 structural draw calls | — | ~38 = 13 batched (street MultiMesh 3, props 5, windows 1, ground/sky 2, panorama/moon 2) + 25 per-instance (6 monsters, 6 pickups/documents, 3 interactables, 10 HUD). The 246–253 measured also counts light and material passes, which this estimate leaves out | `tools/qa_sim/drawcall_estimate.py` | STATIC-ESTIMATE |
| 3 | D11 draw calls | < 350 | **165** after the skyline, sign-off run (173 right after the beauty pass, 175-186 before it; rc14, power_station, same runs; the probe now travels there and gates this count) | perf probe (§0) | MEASURED rc14, OK |
| 4 | Real-time lights, D1 frame | < 8 dynamic, rest baked (`GDD.md:385-386`) | **18** active after distance fade (8 lamps × 2 + 2 pickup lights), 58 without fade. No `LightmapGI` exists anywhere, so nothing is baked | `drawcall_estimate.py`; scene/script scan | STATIC-ESTIMATE, **over budget** |
| 5 | Concurrent particles | < 500 | Live emitters: ash 80 (`main_3d.tscn`) and player dust 60, so 140 at High, 70 at Low, 210 at Ultra. Tier ratios 0.5 / 0.75 / 1.0 / 1.5; Ultra raises `amount` (`settings_manager.gd:516-524`). Transients per event: blood 28, hit spark 10, muzzle 8, explosion 8, checkpoint 20. `vfx_rain` (300), `vfx_dust` (60) and `vfx_strobe` (24) are never instanced | `.tscn` scan | STATIC-ESTIMATE, under budget |
| 6 | RAM | < 800 MB | desktop: one Godot process about 205 MB working set during a bot run (rc14, `tasklist`); never measured on a device | TZ P02 | MEASURED desktop, device step is the owner's |
| 7 | VRAM, textures | < 400 MB (whole VRAM) | Measured on desktop: texture memory **138.9-144.7 MiB**, video memory **160.5-166.3 MiB** (rc14, §0). Static bound before: ≤ 74.3 MiB if all 528 2D textures were resident at 8 bpp, plus about 16 MiB for the shadow map and the MSAA targets | perf probe; `.import` scan | MEASURED rc14 (desktop); device NEEDS-GODOT-RECONFIRM |
| 8 | Texture size | ≤ 2048² hero / ≤ 512² props | 0 textures over 2048 px; 25 over 1024 px | `.import` scan | STATIC-ESTIMATE |
| 9 | Texture format | ETC2/ASTC (`GDD.md:387`) | rc14: `rendering/textures/vram_compression/import_etc2_astc=true` in `project.godot`; the 520 VRAM-compressed textures now import BPTC (desktop) and ASTC (Android) | `project.godot`, `.import` scan | CONFIG, done |
| 10 | Package size | Play caps the base module at 200 MB compressed download; check the current limit in Play Console at upload | Signed AAB **183.1 MB** (rc14, arm64-v8a): base module about 27 MB compressed (libs 24.5, dex 1.8, res 0.7); game data in the install-time asset pack, 155.1 MB compressed. The old 205.5 MB was a desktop PCK | `docs/RELEASE_ARTIFACTS.md` | MEASURED rc14; per-device download size is read in Play Console |
| 11 | Audio, exported | music < 100 MB, SFX < 50 MB | music 37.2 MiB; non-music 24.0 MiB (sfx, one-shots, ambience without `wav_src`, UI, jingles, ending music, `_build`) | file sizes | STATIC-ESTIMATE |
| 12 | Renderer | — | `gl_compatibility` on desktop and mobile (`project.godot:272-273`) | project.godot | CONFIG |
| 13 | Tier effects | GDD C06 | rc14 (`c785b2c`): the no-op SSIL, SSR and volumetric-fog keys are gone from `visual_quality.tres` (13 keys per tier); SSAO is the one tier effect left, and Compatibility supports it | `world_env_setup.gd`, `visual_quality.tres` | CONFIG |
| 14 | Resolution scaling | — | rc14 (`c785b2c`): the bogus `scaling_3d/fsr_upscale` key is removed; Compatibility uses bilinear. The Render Scale slider (0.5-1.0) sets `Viewport.scaling_3d_scale` (`settings_manager.gd`) | project.godot | CONFIG; the slider's effect is NEEDS-GODOT-RECONFIRM |
| 15 | MSAA 3D | — | the project default is `msaa_3d=1` (2x, `project.godot:278`) and the tier picks off, 2x, 2x or 4x (Low to Ultra, `scripts/world_env_setup.gd:20`, `MSAA_BY_TIER`, applied at `:172`); it was 4x on every tier before Session 23 | project.godot | CONFIG; the saving is MEASURED (Session 23) |
| 16 | Frame rate | 30–60 FPS | Desktop iGPU, windowed 1080p: p95 **33.3-34.2 ms** D1 and **40.3-40.4 ms** D11 on quiet runs (§0); device FPS never measured. `max_fps=60` | perf probe (§0) | MEASURED rc14 (desktop); device NEEDS-GODOT-RECONFIRM |
| 17 | Shader warm-up | — | None: no warm-up or precompile code anywhere. Compatibility compiles each material variant on first use | code scan | STATIC; the first-use hitch is NEEDS-GODOT-RECONFIRM |
| 18 | Polygons per district | < 50K | **1.34 M** primitives per frame in D1 and in D11 (rc14, §0): about 27x the budget | perf probe (§0) | MEASURED rc14, **OVER** |
| 19 | Shadows | — | Directional 2048², soft filter 1 (`project.godot:275-276`); the flashlight casts shadows on desktop and none on mobile (`player_3d.gd:256-258`) | project.godot, player | CONFIG |
| 20 | LOD | — | `mesh_lod/threshold_pixels=0.75` (`project.godot:280`) | project.godot | CONFIG |

## 2. Re-measure list for Local, in this order

1. Enable `import_etc2_astc`, reimport, then export the AAB. Record the download size (#9, #10).
2. `tools/qa_sim/guarded_windowed res://scenes/tools/perf_check_scene.tscn` on D1 and on D11
   (power_station). Record draw calls, primitives and objects (#1, #3, #18).
3. On a mid-range Android phone (Profiler / `adb shell dumpsys meminfo`): RAM, VRAM, FPS in the
   DARK and FULL stages, and particle count in a fight (#5, #6, #7, #16).
4. First-use hitch: first flashlight toggle, first monster hit flash and first district load with an
   empty shader cache (#17).
5. Render Scale slider at 0.5: does the 3D buffer shrink under Compatibility? (#14)

## 3. Cheapest levers if a budget fails

- **Lights (#4):** lower the lamp-light pair to one omni per lamp, or shrink the distance-fade range.
  A config change, no batching work.
- **Draw calls (#1):** `drawcall_estimate.py` already puts the mesh floor at ~38. The rest is light and
  material passes, so lever #4 moves #1 as well.
- **Size (#10):** the E7 audio re-encode and the `textures/surfaces`/`textures/ui` narrowing that
  `SIZE_BUDGET.md` lists as not done.
- **Tier table (#13):** drop the no-op SSIL, SSR and volumetric-fog keys, so High and Ultra stop
  promising effects the renderer never draws.

## rc16 before and after (same machine, same probe, windowed, tier 2)

Probe: `tools/qa_sim/rc16_probe <label> <hash> 900` (`scripts/tools/_rc16_probe_runner.gd`): a district cycle (10 cold loads, 10 warm loads), three 300-frame perf reads, the eight staged frames.
Before: `e4bb4df`, `docs/artifacts/rc16/proofs/probe_before.out` with the log `docs/artifacts/rc16/proofs/probe_before.attach.rc16_probe_before.log`.
After: `c3e79e5`, launch 19 (ledger row 19), `docs/artifacts/rc16/proofs/s6_reimport_probe_after_c3e79e5.out` with `...attach.rc16_probe_after.log`; 0 SHADER ERROR, SCRIPT ERROR or Parse Error lines in the log.

| quantity | before | after |
|---|---|---|
| nodes at the start of the probe | 1784 | 1061 |
| nodes with one district built (20 loads, min to max) | 1786 to 1825 | 1062 to 1101 |
| objects at the start | 4886 | 3809 |
| draw calls, D1 (three reads: first, after the cycle) | 179, 160 | 160, 161 |
| draw calls, D11 | 166 | 163 |
| frame p95 ms, D1 | 76.19, 51.45 | 33.70, 50.00 |
| frame p95 ms, D11 | 50.00 | 51.01 |
| cold load ms (10 districts: min, mean, max) | 264, 354, 482 | 214, 317, 384 |
| warm load ms (10 districts: min, mean, max) | 248, 359, 473 | 201, 275, 356 |
| hitches (frames over 50 ms) per transition, mean cold, warm | 1.8, 2.3 | 3.0, 4.1 |
| longest frame of a transition ms, max cold, warm | 144, 150 | 150, 147 |
| texture MiB with a district built | 71.3 to 71.8 | 69.2 to 69.7 |
| video MiB with a district built | 96.8 to 97.3 | 96.8 to 97.2 |

Over the 22 transitions before the staged frames the node count stays inside the band above in both runs (no growth), orphans stay at 6. The probe then stages its frames; the transition after the staged Ultra sprint frame (frame 06, the default tier is set again after it) reads 130.0 MiB texture and 159.6 MiB video with 22 hitches and 1210 ms to settle in the rc16 run (`docs/artifacts/rc16/proofs/s6_reimport_probe_after_c3e79e5.attach.rc16_probe_after.log`, the `stream pass=frames district=industrial` line) and 129.8 MiB, 157.3 MiB, 2 hitches and 479 ms in the rc15 run (`docs/artifacts/rc16/proofs/frames_before.attach.rc16_probe_before.log`): the step up of about 60 MiB in each is in both runs and was not traced.
The frame p95 differs between reads of the same code by up to 16 ms (D1 after: 33.70 and 50.00; before: 76.19 and 51.45); the machine load during a read is not controlled here.
The package size was measured by the one release export at the end of the pass (`aab_verify_rc16.out`): `build/tls.aab` is 183290294 bytes (rc15: 183257097), the base module 26974670 bytes compressed and the install-time asset pack 155283546.

## Session 23 (2026-10-12): the gate, dynamic resolution, the warm-up

- **The gate fails.** `scripts/tools/_perf_check_runner.gd` exits 1 on a D1 of 200 draw calls or more, a D11 of 350 or more, a p95 frame time over 33 ms in either district (the median of three reads of 300 frames, because one read moves by up to 16 ms with the load of the machine, see the rc16 table above) and a video memory over 512 MiB. Check PERF3 tries each edge in the headless closeout; the numbers of Session 22 (D1 142 draw calls, p95 28.79 ms; D11 129, 23.61 ms; video memory 155.8 MiB) pass it. The gate itself is windowed (the headless renderer reports 0 draw calls and the gate skips), so the verdict on this tree is a windowed run, listed in `docs/RUN_STATE.md`.
- **Dynamic resolution.** `scripts/systems/dynamic_resolution.gd`: under 30 FPS for 2 s the 3D scale drops to 0.7 of Render Scale, over 45 FPS for 4 s it returns, the band between holds. On by default on a phone. Check PERF1 steps it with fake readings through every edge.
- **Shader warm-up.** `scripts/post_process_overlay.gd` draws the blur, chroma and rain-lens layers once as an identity at the start, so the first gameplay frame does not compile them. Check PERF2.
- **Draw calls added by the pass.** The pooled bursts are capped at 5 per scene (426 particles with every pooled burst in flight and the world's 154, check VFX6, budget 500). The dressing added 12 draw calls to the suburbs (`dressing hidden` below) and the perf gate reads D1 150 to 154 and D11 136 to 145, under 200 and 350.
- **Where the frame goes: two ablations (launches 20 and 21, `s23_fix_3cef1de` and `s23_fix2_5ad1387`).** `scripts/tools/_perf_ablation_runner.gd` (`tools/qa_sim/guarded_windowed res://scenes/tools/perf_ablation_scene.tscn`) switches one part of the frame off at a time at the spawn of the suburbs (High tier, a 1920 x 1055 window) with a baseline between each pair; the second run also turns the vertical sync off and takes every visible child of the HUD and of the overlay in turn. A GPU time is the mean of 200 or 300 frames of `viewport_get_measured_render_time_gpu`. The baseline of the second run drifted from 25 to 19 ms while it ran, so each part is read against the baselines on both sides of it, and a reading under 1 ms is noise.

  | Part switched off | GPU ms saved (run 1, run 2) | Draw calls |
  |---|---|---|
  | 4x MSAA | 8.9, 5.5 | 0 |
  | the post-process overlay as a whole (grain, vignette, chromatic aberration) | 3.2, 6.8 | 1 |
  | the HUD as a whole | 4.1, 2.3 | 73 |
  | the chromatic aberration alone (a district preset of 0.5 to 1.0 px, a copy of the frame) | -, 1.8 | 1 |
  | the grain and the vignette of the overlay, each | -, 0.5 | 1 |
  | the HUD's own grain (it reads the screen) | -, 0.8 | 1 |
  | the dressing of the district (batches, pools, landmark, rest spot) | 0.9 | 12 |
  | the pools of the lamps at the DARK stage (opacity 0) | 0.9 | 1 |
  | the glow | 0.7 | 0 |
  | the moon's shadows | 0.6 | 2 |
  | the fog cards in the power station | 0 (within the noise) | 0 |

  The fog cards, which had never drawn (CORRECTION_LOG 233), cost nothing measurable now that they do. The 4x MSAA is the largest single part by far.
- **What was changed for it.** The samples of the 3D follow the tier: off at Low, 2x at Medium and High, 4x at Ultra (check MSAA1); the project default is 2x so the menu and a phone start there. A pool of light or a halo whose opacity is 0 (the DARK stage, the first hours of the game) is hidden instead of drawn blind (check POOL1). The HUD and the overlay were not touched: the HUD's cost is spread over its parts and the overlay's layers each cost 0.5 to 1.8 ms.
- **Not built, with the reason:** the LOD swap, occlusion culling and texture streaming (`docs/KNOWN_ISSUES.md`, Session 23).
