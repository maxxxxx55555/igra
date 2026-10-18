# Premium visual pass and the AAA benchmark (Session 23, PV1)

Two halves: what the pass measured about this game's own frames and what each premium item of the directive is in the code (sections 2 to 4), and the comparison with frames of other
games, which cannot be made from here (section 1) and is an owner row with a tool.

## 1. The benchmark comparison: UNVERIFIABLE-HERE

The directive asks for three reference frames from AAA stealth-horror games in a similar light, measured for luminance, saturation and contrast and set against this game's. Those frames
are other studios' pictures: this session cannot capture them from a running copy of a game it does not own, and a copy kept in the repository would be a copyright problem, so
**no AAA number appears in this document and none is claimed.** What is built is the instrument: `python tools/qa_sim/benchmark_frames.py --ref DIR` reads any folder of the owner's
reference frames and prints, for it and for this game's frames, the luminance (Rec. 709, 0..1), the saturation of the lit pixels and the contrast (the standard deviation of the
luminance), the median of each set and the difference. **Owner row B-1, executable:** play a stretch of a game you own with a similar light (a dark street, one lamp), take three
screenshots, put them in a folder outside the repository, run the command, and read the three differences: a luminance difference over about 0.05 means this game is darker than
the reference, a saturation difference over 0.1 means it is greyer, a contrast difference means flatter (negative) or harsher (positive). The tool's demo (`--demo`) proves it on a
synthetic pair; a smoke run on one of this game's own frames in place of a reference printed the table and the difference line, and is not a benchmark.

## 2. This game's own numbers (measured, 55 frames a set)

The frames are the density stills of the pass (five views of each of the eleven districts, English, HUD hidden, `docs/stills/density`), whole, with no part left out. Medians over 55:

| Set | Luminance | Saturation | Contrast |
|---|---|---|---|
| baseline `5d30659` (before the dressing, the landmarks, the palettes, the fog) | 0.160 | 0.142 | 0.161 |
| after, `f49dd9d` | 0.164 | 0.158 | 0.153 |

| View | Luminance before, after | Saturation before, after | Contrast before, after |
|---|---|---|---|
| 01 dark, flashlight on | 0.1925, 0.1913 | 0.153, 0.168 | 0.205, 0.195 |
| 02 rest spot | 0.1603, 0.1703 | 0.157, 0.143 | 0.142, 0.146 |
| 03 street | 0.1552, 0.1642 | 0.122, 0.146 | 0.166, 0.155 |
| 04 block | 0.1461, 0.1481 | 0.143, 0.198 | 0.143, 0.136 |
| 05 skyline | 0.1510, 0.1523 | 0.125, 0.162 | 0.157, 0.134 |

Read honestly: the frame is dark (a mean luminance of 0.16 on 0..1 is the night of the style guide), the saturation rose by 0.015 (the palettes and the fog), the contrast **fell** by 0.009
because the black voids of the blocks are filled with props, pools of light and haze; the rest-spot frame is where the lantern shows (luminance +0.010). The win of the pass is structure, not
brightness, and `docs/DENSITY_MEASURED.md` has the same pairs frame by frame (the dressing hidden against shown in one run). The numbers are refreshed at the final hash of the pass.

## 3. The premium items, one by one

| Item of the directive | State | Evidence or reason |
|---|---|---|
| Light mood per district, aligned to the LUTs | **in** | `district_lights` (an energy and a moon bias for each of the 11 districts) in `assets/config/visual_quality.tres`, read by `scripts/world/streetlight_3d.gd:41`; the ambient, the accent and the weather of each district in `scripts/world/district_themes.gd`; the mood of the districts that share a theme is an owner row (`docs/DISTRICT_SIGNATURES.md`, S-1) |
| Streetlight flicker curve shader synced to the hum | **not wired**, on purpose | `assets/shaders/streetlight_flicker.gdshader` and `assets/env/mat_lamp_flicker.tres` exist and nothing uses them: a flicker is a photosensitivity risk (it would have to sit behind Reduce Flash) and a hum sync needs a per-lamp audio phase; owner decision |
| Wet-asphalt reflective mask shader | **not wired**, on purpose | `assets/shaders/wet_asphalt.gdshader` reads the screen texture, which makes the Compatibility renderer copy the frame every frame, a cost on a phone's tiler; the wet look is carried by the soft wet patches of the dressing and the surface-aware footsteps (`docs/DENSITY_PLAN.md`) |
| Foliage wind-sway vertex shader | **in** | the canopies of the street trees (`scripts/world/street_props.gd:280`), 0.08 m, off with Motion Comfort; check FOLIAGE1 |
| Prop VisibilityRange LOD plan | **not built**, a decision | DEFER-23 in `docs/TZ_DECISIONS.md`: every mesh of the districts is a primitive or a MultiMesh of blocks, there is no lower detail to swap to |
| ACES tonemap | **in** | `tonemap_mode` 3 in every preset of `assets/config/visual_quality.tres`, applied by `_apply_graphics_tier` (`scripts/world_env_setup.gd:181`) |
| Tuned glow and bloom | **in** | the bloom, the intensity, the strength and the HDR threshold of each tier in the same file |
| Volumetric fog on desktop, a height-fog shader on mobile | **the fallback only** | the volumetric fog of the engine is not available in the Compatibility renderer the game ships with; the depth fog of each tier (`fog_density` 0.012 to 0.015) and the ground fog cards of the four fog districts (`assets/shaders/height_fog_card.gdshader`, `scripts/world/district_dressing.gd:282`) are the height-fog fallback |
| SSAO, SSIL, SSR, desktop only | **not applicable** | they are Forward+ features; the preset asks for SSAO only when the rendering method is `forward_plus` (`scripts/world_env_setup.gd:202`) and the game runs Compatibility, so none runs; the wet-asphalt shader carries its own substitute for SSR |
| Auto-exposure with night-safe limits | **not applicable** | no `CameraAttributes` is used; auto-exposure is not in the Compatibility renderer |
| Visual quality presets | **in** | section 4 |
| Shader and material warm-up | **partly** | the post-process shaders (blur, chroma, rain lens) are each drawn for two frames at strength 0 at the start (`_warm_shaders`, `scripts/post_process_overlay.gd:55`); the world's own shaders compile when the first district is built, behind the loading screen |

## 4. Quality presets: Low, Medium, High, Ultra

`SettingsManager.set_graphics_tier` (`scripts/systems/settings_manager.gd:512`) sets five things from the row of `GRAPHICS_TIERS` (line 306) and the rest follow the `graphics_tier` signal:

| Toggle | Low | Medium | High | Ultra | Where |
|---|---|---|---|---|---|
| shadows (the atlas 1024, 2048, 4096) | 0 | 1 | 2 | 2 | `GRAPHICS_TIERS`, `SHADOW_ATLAS` (line 304) |
| textures (mipmap bias 1.0, 0.5, 0) | 0 | 1 | 2 | 2 | `set_texture_quality`, line 589 |
| effects (glow on from 1; shell cases, dust motes and the particle bursts off at 0) | 0 | 1 | 2 | 2 | `set_effects_quality`; `scripts/effects/shell_eject.gd:23`, `scripts/systems/wow_director.gd:55` |
| frame cap (30, 60, 120) | 30 | 30 | 60 | 60 | `FPS_STEPS`, line 302 |
| window size (720p, 1080p, 1440p; no effect on a phone) | 720p | 1080p | 1080p | 1440p | `RESOLUTIONS`, line 303 |
| glow bloom, intensity, HDR threshold | 0.10, 0.40, 1.4 | 0.15, 0.50, 1.3 | 0.20, 0.55, 1.2 | 0.20, 0.55, 1.2 | `assets/config/visual_quality.tres` |
| depth fog density | 0.012 | 0.013 | 0.014 | 0.015 | the same file |
| particle count (the share of each emitter) | 50 % | 75 % | 100 % | 150 % | `particle_ratio`, `_apply_particle_ratio` (line 526) |
| film grain | off | on | on | on | `_apply_grain_tier`, `scripts/ui/hud_3d.gd:361` |
| chromatic aberration on a hit | off | off | on | on | `TIER_CHROMA`, `scripts/post_process_overlay.gd:8` |
| motion blur on sprint | off | off | off | on | `TIER_BLUR`, `scripts/post_process_overlay.gd:9` |
| rain on the lens | off | off | off | on | `TIER_LENS`, `scripts/effects/rain_lens.gd:6` |
| ground fog cards (fog districts) | off | on | on | on | `scripts/world/district_dressing.gd:283` |
| the windows of the skyline (and the old floating window wall hidden) | none: the blocks only | on | on | on | `_low_tier`, `scripts/world/street_props.gd:123`; `with_windows`, `scripts/world/skyline.gd:70` |
| SSAO | off | off | only on Forward+ | only on Forward+ | `ssao_enabled` in the preset and `scripts/world_env_setup.gd:202` |

**Mobile fallback, declared.** A phone starts on **High** (`_settings["graphics_tier"] = 2`, `scripts/systems/settings_manager.gd:84`) with dynamic resolution on (`scripts/systems/settings_manager.gd:121`: the 3D scale drops to 0.7
under load and recovers, `scripts/systems/dynamic_resolution.gd`), and `QualityManager` lowers the tier by itself when the frame rate stays under 30 for 5 s and raises it again, never above what the player chose, after 10 s over 45
(`scripts/systems/quality_manager.gd:14-18`; both limits are no higher than 90 % of the frame cap, which is 30 at Low and Medium, and each drop doubles the wait before the next raise: until Session 23 a tier it had lowered could not be raised, CORRECTION_LOG 241). So the fallback of a weak phone is: the 3D scale first, then the tier down one step at a time, each step removing the most expensive effects (the lens and the blur at
Ultra, the chroma and the fog cards below). The metadata of the preset file names a profile for each platform (`profile_desktop` high, `profile_mobile` medium), and **nothing reads it**: the real default is High on both,
and the choice of Medium for a phone is an owner row (Q-1: set the first-run tier to Medium on a handheld after reading the frame rate of the first device).

## 5. Owner rows

- **B-1** the benchmark comparison (section 1).
- **Q-1** the first-run tier on a phone (section 4), after a read of the real frame rate: the dev iGPU of this machine read a p95 of 35.00 ms at D1 at the final head (`docs/PERF_PASS.md:19`; 28.79 ms at `v8.0.0-shipping`, `docs/PERF_PASS.md:51`) and is not a phone.
- **W-1** the two shaders that exist and are not wired (flicker, wet asphalt): an owner decision with their costs above.
