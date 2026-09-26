# Perf pass: static consolidation at `ce782f8`

Every performance number that can be sourced without running Godot, next to its budget. Budgets
come from GDD §15 (`docs/GDD.md:385-389`, mobile) unless noted.

Tags:
- **STATIC-ESTIMATE:** computed from the repo by the cloud audit (script or file scan).
- **CONFIG:** a setting's value, read from the repo.
- **NEEDS-GODOT-RECONFIRM:** only a windowed or on-device run can settle it. The last measured value
  is given if one exists.

## 1. Numbers

| # | Metric | Budget | Value | Source | Tag |
|---|---|---|---|---|---|
| 1 | D1 draw calls | < 200 | **246** (C7), **253** (rc11), windowed, suburbs spawn | ORDER_PASS battery, TZ P01, FUNCTION_MATRIX X24 | NEEDS-GODOT-RECONFIRM |
| 2 | D1 structural draw calls | — | ~38 = 13 batched (street MultiMesh 3, props 5, windows 1, ground/sky 2, panorama/moon 2) + 25 per-instance (6 monsters, 6 pickups/documents, 3 interactables, 10 HUD). The 246–253 measured also counts light and material passes, which this estimate leaves out | `tools/qa_sim/drawcall_estimate.py` | STATIC-ESTIMATE |
| 3 | D11 draw calls | < 350 | Not recorded separately: `_perf_check_runner.gd:33-52` measures the spawn district and gates its count against 350 | perf probe | NEEDS-GODOT-RECONFIRM (load power_station explicitly) |
| 4 | Real-time lights, D1 frame | < 8 dynamic, rest baked (`GDD.md:385-386`) | **18** active after distance fade (8 lamps × 2 + 2 pickup lights), 58 without fade. No `LightmapGI` exists anywhere, so nothing is baked | `drawcall_estimate.py`; scene/script scan | STATIC-ESTIMATE, **over budget** |
| 5 | Concurrent particles | < 500 | Live emitters: ash 80 (`main_3d.tscn`) and player dust 60, so 140 at High, 70 at Low, 210 at Ultra. Tier ratios 0.5 / 0.75 / 1.0 / 1.5; Ultra raises `amount` (`settings_manager.gd:441-451`). Transients per event: blood 28, hit spark 10, muzzle 8, explosion 8, checkpoint 20. `vfx_rain` (300), `vfx_dust` (60) and `vfx_strobe` (24) are never instanced | `.tscn` scan | STATIC-ESTIMATE, under budget |
| 6 | RAM | < 800 MB | never measured | TZ P02 | NEEDS-GODOT-RECONFIRM (device) |
| 7 | VRAM, textures | < 400 MB (whole VRAM) | ≤ **74.3 MiB** if all 528 2D textures were resident: 520 VRAM-compressed at 8 bpp, 8 lossless at 32 bpp, mipmaps included. Add about 16 MiB for the 2048² directional shadow map, plus render targets (MSAA 4x) | `.import` scan + PIL sizes | STATIC-ESTIMATE (texture part only) |
| 8 | Texture size | ≤ 2048² hero / ≤ 512² props | 0 textures over 2048 px; 25 over 1024 px | `.import` scan | STATIC-ESTIMATE |
| 9 | Texture format | ETC2/ASTC (`GDD.md:387`) | 520 of 528 are VRAM-compressed, but **imported as BPTC only**. `rendering/textures/vram_compression/import_etc2_astc` is not set in `project.godot`, and the Android preset's `texture_format/etc2_astc=true` (`export_presets.cfg:39`) is not what Godot checks. Godot's Android exporter refuses to export without the project setting: `platform/android/export/export_plugin.cpp` → "ETC2/ASTC texture compression is required for Android export" | `project.godot`, `.import` scan, Godot source | CONFIG, **AAB export blocker** (RELEASE_RUNBOOK step 1) |
| 10 | Package size | Play caps the base module at 200 MB compressed download; check the current limit in Play Console at upload | Desktop PCK **205.5 MB** after the E2–E4 exclude pass (`docs/SIZE_BUDGET.md:171`), measured on an older tree | `SIZE_BUDGET.md` | NEEDS-GODOT-RECONFIRM: build the AAB and read its download size |
| 11 | Audio, exported | music < 100 MB, SFX < 50 MB | music 37.2 MiB; non-music 24.0 MiB (sfx, one-shots, ambience without `wav_src`, UI, jingles, ending music, `_build`) | file sizes | STATIC-ESTIMATE |
| 12 | Renderer | — | `gl_compatibility` on desktop and mobile (`project.godot:295-296`) | project.godot | CONFIG |
| 13 | Tier effects | GDD C06 | High and Ultra turn on SSAO (supported by Compatibility per godot-docs master), SSIL and volumetric fog (**not** supported by Compatibility, so no-ops), and `ssr_enabled` (applied by no script; Compatibility has no SSR either). 21 of the 52 keys in `visual_quality.tres` are read by no shipped script (list in `docs/SLOP_REPORT_V2.md`) | `world_env_setup.gd:176-190`; godot-docs `tutorials/rendering/renderers.rst` | CONFIG |
| 14 | Resolution scaling | — | `scaling_3d/fsr_upscale=true` (`project.godot:302`) is not a Godot setting (the real keys are `scaling_3d/mode`, `scale`, `fsr_sharpness`), and FSR 1/2 need Forward+ anyway. Compatibility uses bilinear. The Render Scale slider (0.5–1.0) sets `Viewport.scaling_3d_scale` (`settings_manager.gd:492-497`) | project.godot; godot-docs `tutorials/3d/resolution_scaling.rst` | CONFIG; the slider's effect is NEEDS-GODOT-RECONFIRM |
| 15 | MSAA 3D | — | `msaa_3d=2` (4x) on every tier, not scaled by the graphics tier (`project.godot:300`) | project.godot | CONFIG |
| 16 | Frame rate | 30–60 FPS | `max_fps=60` (`project.godot:16`); FPS never measured on a device | project.godot | NEEDS-GODOT-RECONFIRM |
| 17 | Shader warm-up | — | None: no warm-up or precompile code anywhere. Compatibility compiles each material variant on first use | code scan | STATIC; the first-use hitch is NEEDS-GODOT-RECONFIRM |
| 18 | Polygons per district | < 50K | Geometry is procedural (MultiMesh builders), so it can't be counted statically. The perf probe already logs `RENDER_TOTAL_PRIMITIVES_IN_FRAME` (`_perf_check_runner.gd:34`) to a local log | perf probe | NEEDS-GODOT-RECONFIRM |
| 19 | Shadows | — | Directional 2048², soft filter 1 (`project.godot:297-298`); the flashlight casts shadows on desktop and none on mobile (`player_3d.gd:256-258`) | project.godot, player | CONFIG |
| 20 | LOD | — | `mesh_lod/threshold_pixels=0.75` (`project.godot:303`) | project.godot | CONFIG |

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
