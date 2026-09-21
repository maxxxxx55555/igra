# RENDERING_DIAGNOSIS — magenta 3D world on real GPU, clean headless (static root-cause menu for R0)

**Role:** independent static diagnostician. No engine run for this file — every claim cites
`file:line` or a `project.godot` / `.import` / `export_presets.cfg` config key. Evidence baseline
`c1ebeec` ("chore: release readiness v7.5"). Symptom under diagnosis is the one captured in
`docs/KNOWN_ISSUES.md` ("CRITICAL, NEW, NOT FIXED (2026-09-21): 3D world renders as severe
magenta/pink corruption in windowed mode"): jagged scanline-like streaks over the ground plane,
hundreds of scattered magenta/purple dots, one object with concentric magenta rings; HUD
(health/stamina/battery bars, radar, all text) perfectly clean on top; GPU `AMD Radeon(TM)
Graphics` (integrated), renderer `gl_compatibility`; headless runs clean.

**The two topology facts any root cause must explain:**
1. Corruption is confined to the composited 3D layer (particles + world geometry); the 2D HUD
   chrome is clean (`docs/KNOWN_ISSUES.md`, same entry).
2. Headless (dummy renderer) never reproduces it — nothing is sampled or rasterized on a real
   GL context there (`tools/check.sh` engine gates all run `--headless`, see `tools/check.sh:149-151`).

Riskiest assumption of this whole document (verified below where it bites): that the corruption
is a real on-screen render bug and not a `capture_stills` framebuffer-readback artifact —
`docs/KNOWN_ISSUES.md` explicitly leaves this open; the R0 discriminating test is the last
section of this file.

---

## (a) rendering_method vs likely GPU class — configs ranked by compatibility

Current config (all cited keys live in `project.godot`):

| key | value | line |
|---|---|---|
| `application/config/features` | `PackedStringArray("4.7", "GL Compatibility")` | `project.godot:15` |
| `rendering/renderer/rendering_method` | `"gl_compatibility"` | `project.godot:304` |
| `rendering/renderer/rendering_method.mobile` | `"gl_compatibility"` | `project.godot:305` |

Ranking of the three Godot 4.7 rendering methods against the likely GPU population (integrated
AMD/Intel, min-spec Android per `docs/RELEASE_CHECKLIST.md`, Web):

| rank | config | compat class | verdict for this project |
|---|---|---|---|
| 1 (safest) | `gl_compatibility` (current, `project.godot:304-305`) | OpenGL 3.3 / GLES3 — runs on every target including weak iGPUs and min-spec Android | **correct choice — keep.** The magenta exists *inside* this method; switching methods would only mask it on machines that can run the others |
| 2 | `mobile` | Vulkan 1.0+ — most modern Android, most desktops since ~2013; drops old Intel/VMs | higher-fidelity, narrower reach; no evidence needed for R0 |
| 3 | `forward_plus` | Vulkan 1.0+ desktop-class; requires newer mobile GPUs | worst reach; also the only method where SSR/SSIL/volumetric fog/SSAO's full quality path is a supported assumption (see §d) |

So the *method* is already the most compatible one. The compat-leverage in R0 is not in
switching `rendering_method` — it is in the per-feature config that rides on top of it
(MSAA/FSR, VRAM texture formats, screen-space effects toggled on at the default graphics tier).

Riskiest assumption (a): "gl_compatibility on Godot 4.7 emits GLES3/GL3 and nothing else" —
verified by `project.godot:15` feature tag `"GL Compatibility"` and the `.import` `s3tc_bptc`
format group (§b), which is the desktop-GL VRAM group.

## (b) VRAM-compressed textures — census and the Lossless test set

Census over all 539 `*.import` sidecars (scripted `grep` census, rerunnable):

| config key | value | count |
|---|---|---|
| `compress/mode` | `2` (VRAM Compressed) | **531** |
| `compress/mode` | `0` (Lossless) | 8 (`assets/textures/enemies/{architect,brute,burner,hound,rotter,sniper,tvar}_512.png`, `assets/textures/environment/rusty_metal.png`) |
| `compress/high_quality` | `true` (→ BPTC/BC7 on desktop) | **531** (the same 531) |
| `compress/high_quality` | `false` | 8 (the Lossless ones carry the default) |
| metadata `imported_formats` | `["s3tc_bptc"]` only | **539 — zero `etc2/astc` variants in the whole import cache** |
| `mipmaps/generate` | `true` | 76 (44 `assets/textures/tiles`, 27 `assets/textures/surfaces`, 3 `assets/textures/environment`, 2 `assets/textures/sky`) |
| `mipmaps/generate` | `false` | 463 (UI, icons, FX sprites, items…) |

Sample proof: `assets/art/menu_bg.png.import` `compress/mode=2`, `compress/high_quality=true`,
`path.bptc="…bptc.ctex"`, `metadata/imported_formats: ["s3tc_bptc"]`, `mipmaps/generate=false`;
`assets/textures/tiles/gas_station_floor.png.import` same format group with `mipmaps/generate=true`
(mip census above).

Why this is a first-class suspect for *this* symptom:

- `compress/high_quality=true` + `compress/mode=2` imports **BPTC/BC7** (the `.bptc.ctex` dest
  files), not the older S3TC/DXT1 pair. BC7 decode is silently broken or lossy-garbage in a
  known class of weak/integrated GL drivers; garbage decode reads as colored (magenta-biased)
  pixel noise — matching "dots"/"streaks" over textured surfaces.
- The one observed object with **concentric rings** is the textbook signature of a sampled
  compressed **mip chain** whose upper levels decode to garbage (each mip level shows as a
  ring band). Only 76 textures have mipmaps — and those are exactly the world-geometry
  textures (tiles/surfaces/sky). The HUD that renders clean is drawn from the 463 mipless
  imports plus font textures — clean HUD + dirty mipped world is what this failure mode
  predicts.
- `imported_formats: ["s3tc_bptc"]` on all 539: nothing in this cache can decode on a GPU that
  only does ETC2/ASTC (i.e. most min-spec Android). `export_presets.cfg:39` (Android preset)
  sets `texture_format/etc2_astc=true`, but the Web preset ships desktop formats only —
  `export_presets.cfg:55-56` `vram_texture_compression/for_desktop=true`,
  `vram_texture_compression/for_mobile=false` → mobile-web players get a texture-load-fail
  build. (`tools/gen_astc_imports.py:10-24` documents the intended ASTC-on-Android strategy;
  the current cache shows the mobile variants were never imported on this machine.)

**Recommended Lossless test set** (5 files, flips `compress/mode=2` → `0`, re-import, re-capture
the same 3 districts):

1. `assets/textures/tiles/suburbs_floor.png` (mipped ground tile — the "scanline streaks across
   the ground plane" surface class),
2. `assets/textures/surfaces/asphalt_512.png` (mipped surface),
3. `assets/textures/sky/night_sky_panorama_2048x1024.png` (mipped, huge, always on screen),
4. `assets/textures/fx/dust.png` (the particle sprite used by rain AND dust VFX —
   `scenes/vfx/vfx_rain.tscn:3`, `scenes/vfx/vfx_dust.tscn:3` — the "hundreds of scattered
   dots" surface class),
5. `assets/textures/enemies/architect_512.png` — control, already `compress/mode=0`; if the
   Architect was one of the clean objects in the corrupted stills, that is positive evidence
   for this theory.

Alternative one-line probe (whole-population A/B): set `compress/high_quality=false` (S3TC
instead of BPTC) on the same 5 files — separates "BC7 decode broken" from "all VRAM decode
broken".

Riskiest assumption (b): that `compress/high_quality=true` really produced BC7 payloads —
verified by the `.bptc.ctex` dest-file suffix and `path.bptc` key in every sampled sidecar
(`assets/art/menu_bg.png.import`, `assets/art/coin_icon.png.import`).

## (c) shader sources — constructs that compile on dummy but can fail/garbage on real GL

Ranked suspects. "Live" = actually reached at runtime (traced to a load site), because
`docs/AGENT_ZONES.md`'s claim that the W2-W10 shaders have "zero consumers" is only true for the
*world-material* ones — several shaders are wired from code and are very much live.

| rank | suspect | evidence | why it fits "clean headless / dirty real GL" |
|---|---|---|---|
| C1 | `grain_overlay.gdshader:12` — `uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap` | live: `scripts/ui/hud_3d.gd:263` builds a full-rect ColorRect with it; `hud_3d.gd:271-273` shows it whenever `graphics_tier > 0` (default 2, `scripts/systems/settings_manager.gd:79`) | the project's OWN hazard note documents this exact class — `wet_asphalt.gdshader:5-6`: "The screen tap uses filter_linear WITHOUT mipmaps: mipmap blur reads show renderer-specific artifacts on Compatibility". A `filter_linear_mipmap` sampler over a mipless screen texture is undefined sampling on GLES3 — garbage texels on weak drivers. Dummy renderer never samples → clean headless. |
| C2 | inline chroma shader — `textureLod(screen_texture, SCREEN_UV ± offset, 0.0)` ×3, **opaque full-frame screen copy even at amount 0** | `scripts/post_process_overlay.gd:70-85`; live: `scenes/main_3d.tscn:84-85` attaches `scripts/post_process_overlay.gd` (ext_resource id 9 at `main_3d.tscn:10`); default `amount_px_1080p = 0.0` (`post_process_overlay.gd:66`) yet the pass still runs and replaces the frame with a screen readback every frame (`post_process_overlay.gd:83` `COLOR = vec4(r,g,b,1.0)`) | `textureLod` on `hint_screen_texture` + MSAA/FSR viewport (§d) is the classic undefined-resolve path on integrated GL. BUT the HUD-clean topology argues this pass is *passing through* a clean copy (its output covers the HUD region too — if its readback were globally garbage, the HUD would be garbage) → rank stays high as a hazard/waste, mid as the *sole* cause of this symptom. |
| C3 | inline colorblind shader — screen tap + dynamic branching | `scripts/systems/settings_manager.gd:320-329` (`hint_screen_texture, filter_linear` at :323) | only active when `colorblind != 0` (`settings_manager.gd:339-347`) — default is 0 (`settings_manager.gd:92`). Off in the captured runs unless a save carried it. Cheap A/B: force `colorblind=0`. |
| C4 | `scripts/shaders/asphalt.gdshader:9` / `facade.gdshader:8` — `fract(sin(dot(p, …)) * 43758.5453)` hash | precision-dependent classic: `sin` of large arguments loses all precision on mediump/weak ALUs → procedural pattern garbage. **Currently zero load sites** (`grep` of scenes/scripts: `street_builder.gd:47,59` loads `_TEX_ASPHALT`/`_TEX_CONCRETE` *textures*, not these shaders) — not live, not the cause, do not chase | documented so nobody "fixes" a dead file while the live suspects wait |
| C5 | `height_fog_card.gdshader:17` — `uniform vec2 drift : hint_range(-0.2, 0.2)` | `hint_range` is a float/int hint; on a `vec2` uniform this is parse-fragile across engine versions. File is **not live** (zero load sites; its `mat_*` twin family below ditto) | listed as source debt only |

Zero-consumer files (verified by `grep -r` over `*.tscn/*.gd`): `wet_asphalt.gdshader`,
`foliage_sway.gdshader`, `streetlight_flicker.gdshader`, `height_fog_card.gdshader`,
`contact_shadow.gdshader`, `menu_parallax.gdshader`, `asphalt.gdshader`, `facade.gdshader`, and
the `assets/env/mat_{wet_asphalt,foliage_sway,lamp_flicker}.tres` wrappers (the `.tres` files
reference their shaders at `assets/env/mat_*.tres:3` but nothing references the `.tres`). The
orphaned `assets/_orphaned/assets/shaders/fog_depth.gdshader` is in quarantine, fine.

Live shader map (for the lead dev's A/B runs): `damage_vignette.gdshader` ←
`scripts/effects/damage_indicator.gd:23`; `flashlight_cone.gdshader` ←
`scripts/player/player_3d.gd:161-166`; `grain_overlay.gdshader` ← `scripts/ui/hud_3d.gd:263`;
`ui_panel.gdshader` ← `scripts/ui/pause_menu.gd:78`, `scripts/ui/weapon_compare_ui.gd:65`;
plus the 4 inline `Shader.new()` sources (`post_process_overlay.gd:34-35,70-85,108-120,134-143`)
and the colorblind one (`settings_manager.gd:320-329`).

Riskiest assumption (c): that Godot 4.7's shading-language compiler does not itself reject
`filter_linear_mipmap` on `hint_screen_texture` at parse time (if it did, the headless
`i18n_check`/`asset_check` class gates would show errors) — verified clean headless behavior
plus `wet_asphalt.gdshader:5-6`'s on-disk testimony that such reads *do* run and produce
"renderer-specific artifacts on Compatibility".

## (d) world_environment / volumetric / SSR / SSAO — the elimination in KNOWN_ISSUES is VOID

This is the most important static finding of the pass.

**What KNOWN_ISSUES claims:** "not SSR/SSIL/SSAO/volumetric fog (all four are Forward+/Mobile-only
features not supported by `gl_compatibility` — disabled all four in a scratch edit of
`assets/env/night_environment_desktop.tres` and re-captured; corruption was unchanged)".

**Why that elimination proves nothing:** `assets/env/night_environment_desktop.tres` (and
`night_environment_mobile.tres`, and `camera_attributes_night.tres`) has **zero load sites** —
`grep -r "night_environment"` over `*.gd/*.tscn` returns nothing outside `assets/env/` itself.
The runtime environment is built in code by three paths:

1. `scripts/world_env_setup.gd:38-60` (attached at `scenes/main_3d.tscn:88-89`): builds a fresh
   `Environment` with `ssao_enabled = false`, `ssil_enabled = false`,
   `volumetric_fog_enabled = false` (`world_env_setup.gd:55-57`) — then…
2. `scripts/world_env_setup.gd:163-188` (`_apply_graphics_tier`, wired from VISUAL_PASS W1)
   **loads `assets/config/visual_quality.tres` and applies the tier dict** — whose
   `metadata/high` profile contains `"ssao_enabled": true, "ssil_enabled": true,
   "ssr_enabled": true, "volumetric_fog_enabled": true` (`assets/config/visual_quality.tres:8`),
   applied at `world_env_setup.gd:182-184` (`ssao_enabled`/`ssil_enabled`/
   `volumetric_fog_enabled` — note SSR is applied elsewhere, see 3).
3. `scripts/systems/settings_manager.gd:486-496` (`set_effects_quality`) sets
   `env.ssao_enabled = idx >= 2`, `env.ssr_enabled = idx >= 2` — and the default settings are
   `graphics_tier = 2  # High` / `effects = 2  # High` (`settings_manager.gd:79,88`), with
   `set_graphics_tier` forwarding to `set_effects_quality(preset["effects"])` and
   `GRAPHICS_TIERS` tiers 2-3 mapping `effects: 2` (`settings_manager.gd:262-267,429-437`).

So at the **default** profile the live Environment has SSAO + SSIL + volumetric fog + SSR all
enabled (`visual_quality.tres` high; `settings_manager.gd` for SSR) — while running
`gl_compatibility`. The A/B in KNOWN_ISSUES edited a dead `.tres`, so "unchanged" was guaranteed
regardless of causation. **The elimination must be redone on the live path** (one-line edits in
`world_env_setup.gd:182-184` / `settings_manager.gd:494-495`).

Why this class fits the symptom: screen-space effects paint garbage *only over the composited
3D layer* (the 2D HUD draws after the 3D pass and stays clean — exactly the observed topology),
and only on a real GL context (dummy ignores them — clean headless). SSR garbage in particular
tends to smear colored noise along reflected screen content (streaks over the ground plane);
AO-buffer garbage reads as dark/light noise dots. Concentric rings can come from SSR on a
curved/highlight object or from the mip-chain class of §b — the two are separated by the
discriminating tests below.

Also in the fog department: `night_environment_desktop.tres:46-48` carries
`volumetric_fog_enabled = true` + density/albedo (dead config, but see (d)-fix 5 — it must not
be wired as-is), and `visual_quality.tres` high also sets `"auto_exposure": true` (applied via
the camera-attributes path or not at all — `camera_attributes_night.tres` is likewise zero-load;
`world_env_setup.gd:182-188` does not apply it).

Riskiest assumption (d): that Godot 4.7's `gl_compatibility` actually honors (partially or
fully) `ssao_enabled`/`ssr_enabled`/`volumetric_fog_enabled` instead of hard-ignoring them —
if 4.7 Compatibility hard-ignores them, this class demotes below §b and the fix is still free
hygiene. The R0 toggle test (fix 2 below) answers it in one capture.

---

## Candidate fixes ranked 1..N — the R0 menu

Each row: exact edit, evidence, expected tell-tale. Do them in order; stop when the stills go
clean and record which number fixed it.

| # | exact config/edit | evidence | what it explains / tell-tale |
|---|---|---|---|
| **1** | **A/B the live screen-space toggles**: in `scripts/systems/settings_manager.gd:494-495` force `env.ssao_enabled = false; env.ssr_enabled = false` (or run one capture with Effects tier ≠ High via `set_effects_quality(0)`), and in `scripts/world_env_setup.gd:182-184` clamp `ssao/ssil/volumetric_fog` to `false`. Re-capture same 3 districts. | §d; void elimination in `docs/KNOWN_ISSUES.md` | whole-class screen-space garbage confined to the 3D layer. If clean here → root cause is the effects stack on this GL driver; ship with the compat clamp (`env.*` guarded by `RenderingServer.get_current_rendering_method() == "gl_compatibility"`). |
| **2** | **Lossless test set** (§b, 5 files `compress/mode=0`, re-import, re-capture) — control = `architect_512.png` (already lossless) | §b census; ring signature | BPTC/mip decode garbage. If clean here → root cause is compressed-texture decode; ship `compress/high_quality=false` (S3TC) on mipped world textures + import `etc2/astc` variants for mobile. |
| **3** | **Framebuffer chain A/B**: `project.godot:310` `anti_aliasing/quality/msaa_3d=2` → `0`, `project.godot:312` `scaling_3d/fsr_upscale=true` → `false` (keep `scaling_3d/scale=0.8` at :311 for the second run if the first is inconclusive) | MSAA + FSR + sub-native scale is the standard undefined-resolve hazard for `hint_screen_texture` readers (`grain_overlay.gdshader:12`, `post_process_overlay.gd:72-84`, `settings_manager.gd:323`) and for 3D resolve in general | if clean → ship MSAA 2× or FXAA-on-GL for tier High; keep FSR only where tested. |
| **4** | **Screen-texture overlay hygiene (one-liners, worth doing regardless)**: `grain_overlay.gdshader:12` `filter_linear_mipmap` → `filter_linear` (the file's own documented hazard, `wet_asphalt.gdshader:5-6`); `post_process_overlay.gd:66` — skip building/drawing the chroma pass entirely when `amount_px_1080p == 0` (it currently forces a full-frame readback every frame for an identity copy) | §c C1/C2 | removes two undefined-behavior paths + one per-frame full-screen readback (perf). May not be *the* magenta (HUD-clean topology), but it is unambiguous source debt with a documented hazard note. |
| **5** | **Config-soup hygiene**: delete or wire `assets/env/night_environment_{desktop,mobile}.tres` + `camera_attributes_night.tres` (zero load sites but carry `ssr/volumetric_fog_enabled = true`, `night_environment_desktop.tres:40-48`) and drop `"ssr_enabled"/"volumetric_fog_enabled"` from `assets/config/visual_quality.tres` `metadata/high` unless fix 1 proves them safe on GL | §d; `grep` zero-load proof | prevents the next agent from re-enabling the effect class through the "dead" door; removes the trap that voided the first A/B. |
| **6** | **Mobile/Web texture formats**: enable `rendering/textures/vram_compression/import_etc2_astc` (project setting; currently absent from `project.godot` = default) and re-import so sidecars grow `etc2/astc` variants (`imported_formats` is `["s3tc_bptc"]` on all 539 today); flip `export_presets.cfg:56` `vram_texture_compression/for_mobile=false` → `true` for the Web preset | §b census; `export_presets.cfg:55-56` | not the desktop magenta, but it is a *guaranteed* broken-texture build for mobile-web and a risk for min-spec Android — fix before store shots. |
| **7** | **Capture-path truth test** (no game change): run `res://scenes/tools/capture_stills_scene.tscn` windowed and have a human watch the live window while PNGs are written (`scripts/tools/_capture_stills_bootstrap.gd:41-52` saves via `get_tree().root.get_texture().get_image()`); second run with `_shot()` temporarily saving `img.save_png` **and** `img.duplicate()` sampled at the same tick — compare live-eye vs PNG | `docs/KNOWN_ISSUES.md` "Not established, genuinely unknown" paragraph | settles render-bug vs readback-artifact — the one meta-question that decides whether fixes 1-6 are needed at all on this machine. |

Suggested R0 order: run **7** first (5 min, decides everything downstream), then **1**, **2**,
**3** as one-variable A/B captures, applying **4-6** as hygiene regardless of which A/B wins.

## Residual open questions (honest gaps)

- Whether the failing GPU's driver (Windows AMD Adrenalin vs Mesa radeonsi — the
  "ATI Technologies Inc." lspci string does not decide it) is in the BC7-broken population; fix
  2's control file answers this empirically.
- Godot 4.7 Compatibility's exact support matrix for SSAO/SSR/volumetric fog (this document
  cites the repo's own claim (`docs/KNOWN_ISSUES.md`) that all four are Forward+/Mobile-only;
  if 4.7 added partial Compatibility support, that raises the prior for fix 1 — which is
  exactly why it is ranked first).
