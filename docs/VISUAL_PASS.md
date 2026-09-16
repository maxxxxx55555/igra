# VISUAL PASS — AAA environment / material / UI (2026-09-15)

Owner: visual-pass agent. Scope: `assets/shaders/**`, `*.tres`, `scenes/vfx/**`,
UI theme resources, `assets/config/visual_quality.tres`, this doc. No `.gd`,
no screens, no options/settings screen, no i18n/cards touched.

Canon: GDD §11 > `docs/STYLE_GUIDE.md` > `docs/VISUAL_AUDIO_SPEC.md` §1 >
`docs/ART_UI_STYLE.md`. Note: `docs/CARD_ART_BRIEF.md` (named in the task)
does not exist in this repo; the brief above is what was actually followed.
`ART_UI_STYLE.md`'s "Tonemap AgX, do not change" is stale: GDD §11 mandates
ACES, and the live `world_env_setup.gd` AGX override contradicts GDD.

Skill: `ponytail` (full) — reuse before writing; runtime `.gd` owns every
live value, so tunable state ships as presets + shaders + wiring spec.

## 1. Renderer truth table (GL Compatibility on BOTH profiles)

`project.godot` pins `gl_compatibility` for desktop and mobile. Per the
official Godot 4 renderer comparison, on Compatibility:

| Feature | Desktop (Compat) | Mobile (Compat) | Pass decision |
|---|---|---|---|
| ACES tonemap | works | works | both presets use ACES (3) |
| Glow / bloom | works | works | tuned both; minimal on mobile |
| Adjustments + LUT | works | works | LUT kept; contrast 1.03 / sat 0.92 both |
| Depth + height fog | works | works | exp + height fog both; denser height on mobile |
| SSAO | works | avoid (cost) | desktop on (1.2/0.8); mobile off + contact-blob substitute |
| SSIL / SSR | no-op | no-op | desktop preset carries `true` as Forward+ intent; working substitute = wet-asphalt screen reflections (SSR) |
| Volumetric fog | no-op | no-op | desktop preset carries `true` as Forward+ intent; working substitute = fog cards + height fog |
| Auto-exposure | no-op (Forward+ only) | no-op | `camera_attributes_night.tres` holds night-safe limits (min 200 / max 800 ISO, scale 0.25, speed 0.35); working fallback = fixed `exposure_multiplier` 1.0 + `tonemap_exposure` 1.0 |
| Screen texture in spatial shaders | works | works | wet asphalt uses `filter_linear` WITHOUT mipmaps (mip blur artifacts on Compat) |
| DoF | no-op | no-op | not shipped (unasked, unsupported) |

## 2. Before / after parameter table

"Before" = live value traced in code/scenes, not the dead `.tscn` default
(`world_env_setup.gd` overrides `world_env.tscn` at runtime).

| # | Feature | Before | After | Why | Mobile behavior |
|---|---|---|---|---|---|
| E1 | Tonemap | AGX (code) / Filmic (tscn) | ACES both presets | GDD §11 canon; higher-contrast night rolloff for single-source language | same (supported) |
| E2 | Exposure | `tonemap_exposure` 0.9, no CameraAttributes | 1.0 + `camera_attributes_night.tres` (AE 200–800 ISO, scale 0.25, speed 0.35) | 0.9 was an untracked dim; AE band prevents black-lift pumping | fixed exposure (AE is Forward+ only) |
| E3 | Glow threshold | 1.0 (blooms the fog wash) | 1.2 desktop / 1.4 mobile / 1.3 medium | only true brights (lamps 1.6, flashlight, emissives) bloom | tighter + weaker (bloom 0.1, int 0.4) |
| E4 | Glow bloom/int/strength | 0.15–0.25 / 0.6 / 1.0 (postfx presets) | desk 0.2/0.55/1.1, mob 0.1/0.4/1.0, levels 2–4 tuned | less wash, tighter halo around strong sources | minimal glow (art-bible mobile rule) |
| E5 | Fog density/color | 0.012–0.015, `#1a2133` | 0.013, `#1a2133` (canon band kept) | mid-band; runtime `_fog_multiplier` still scales by tier | same |
| E6 | Height fog | none | height 2.0 m, density 0.03 desk / 0.05 mob | ground-hugging night air; the mobile volumetric fallback | denser (leans on it harder) |
| E7 | Fog sky affect | 1.0 default (starfield washed out) | 0.1 | crisp panorama stars, soft horizon | same |
| E8 | SSAO | off (setup) / default 2.0 at effects-tier 2 (harsh) | desk on: intensity 1.2, radius 0.8; mob off | 2.0 too crude for muted palette; 1.2 = documentary contact | off; contact-shadow blobs instead |
| E9 | SSIL / SSR / volumetric | SSR on at tier 2 (silent no-op) | desk `true` (Forward+ intent), mob `false` | honest declaration; substitutes do the real work on Compat | off; substitutes below |
| E10 | SSR substitute | none | wet-asphalt screen reflection (fresnel-weighted, roughness-distorted) | real puddle reflections, one screen tap, Compat-safe | strength 0.85/0.5/0.0 (low = mask + roughness only) |
| E11 | Volumetric substitute | none | fog cards (procedural alpha quads, self-fade near/far) + height fog | creek/valley/fog-district volume without compute fog | on/on/off (low keeps depth fog only) |
| E12 | Adjustments | LUT on, contrast/sat default | LUT kept; contrast 1.03, saturation 0.92 | muted desaturated documentary grade; LUT still applied per-district at runtime | same (supported) |
| E13 | Ambient base | stage-driven 0.12/0.20/0.30 (setup); factory fallback 0.5 (off-canon) | preset base 0.06; factory fix in W10 | behavior stays code-owned; preset is a safe PARTIAL-stage base | same |
| L1 | Moon bias | bias 0.1 / normal_bias 2.0 (tscn, live) | 0.06 / 1.2 + per-district mult (W10) | 0.1 washes contact; tighten, verify on device | same (one global light) |
| L2 | Streetlight energy | FULL 3.5/1.5, STREETS 2.5/1.0, PARTIAL 1.4/0.5; color brass; shadows off | bases kept × per-district mult 0.9–1.15 (§3) | LUT-mood-aligned punch (fog districts cut fog; hospital/police stay dim); color stays brass per canon; shadows stay off (perf) | same values (light count unchanged) |
| L3 | Lamp flicker | Light3D flicker in code only; lamp mesh static emissive | `streetlight_flicker.gdshader`: same curve family (12 Hz + dropouts), world-pos phase, `lit` 0..1 ramp, `hum_level` sync | mesh and light agree; turn-on ramp for first_light/cascade beats | on; `hum_level` static 1.0 on low |
| L4 | Hum bus | none (pool → Master default) | `Hum` bus → sends to `SFX` (appended, no index shift) | flicker↔hum sync tap; SFX slider still governs level | same routing |
| M1 | Ground material | flat albedo + roughness 0.95 | wet asphalt (§2 E10) + `mat_wet_asphalt.tres` | reflective night streets, procedural (no new binaries) | reflection scaled, mask kept |
| M2 | Leaves material | flat green StandardMaterial3D | `foliage_sway.gdshader` + `mat_foliage_sway.tres` (height-weighted wind, model-origin phase) | living park/suburbs crowns; batched-MultiMesh-safe | sway × 1.0/0.6/0.25 |
| M3 | Prop LOD | distance_fade on streetlights only (22 m/8 m) | VisibilityRange plan §5 (ranges + fade margins per class) | draw-call budget guard for D11 | tighter ranges on low (×0.7) |
| V1 | Rain | none (strength value only) | `vfx_rain.tscn`: 300 streaks, box 36×2×36 m, 0.8 s loop, preprocessed | weather finally visible; fixed-Y billboard streaks | 300/180/100 via `amount_ratio` |
| V2 | Dust/haze | none (ash only, global) | `vfx_dust.tscn`: 60 motes, r6 sphere, 6 s loop | interior/drizzle air; doubles as WeatherVFX `FogDrops` | 60/36/20 |
| V3 | Strobe | none | `vfx_strobe.tscn`: 24-particle one-shot, reuses `vfx_burst.gd` | blinding flash beat; auto-frees (`finished→queue_free`) | full (one-shot, cheap) |
| V4 | Particle sim cost | full rate always | `particle_fixed_fps` 0/0/30 | halves sim cost on low only | 30 fps sim on low |
| U1 | Type scale | provider 16/22/30; menu Title hardcoded 44; tls fallback 18/32 | display 44 / huge 30 / title 22 / body 16 / small 13 / mono 15 (both `.tres` + provider-parity spec W9) | one scale; 44 adopts the shipped Title size as token | same (resolution-independent) |
| U2 | Focus outlines | none anywhere | brass 2 px focus ring (Button + LineEdit in `theme_tls.tres`; Button in `theme_main.tres`; W9 for provider) | keyboard/controller navigation readability | same |
| U3 | Disabled states | provider fallback = same-as-normal box; tls = none | dimmed steel text + panel-edge border + 0.35-alpha fill | readable affordance without texture dependency | same |
| U4 | Corner radius | `theme_main.tres` buttons radius 8 (canon violation) | 0 everywhere (chamfer-only) | STYLE_GUIDE / art-bible compliance | same |
| U5 | Screen transitions | ad-hoc (0.35 fade default / 0.18 manager / instant Routes) | per-screen table §6 (all screens EXCEPT `settings_screen.tscn`) | consistent rhythm; reuses FadeTransition + TransitionManager | same (tweens are cheap) |
| U6 | Menu parallax | none (flat ColorRect menus) | `menu_parallax.gdshader` (pointer offset + idle drift, zoom 1.06) over loading art | subtle depth without new assets | strength × 1.0/0.7/0.4, drift kept |

## 3. Per-district light table (aligned to shipped LUT moods)

Lamp color stays brass `#c9a24a` in ALL districts (STYLE_GUIDE §1;
hospital/police coolness lives in their LUT + ambient only, per
VISUAL_AUDIO_SPEC §1). `energy_mult` scales the `_update_light` bases
(3.5/1.5, 2.5/1.0, 1.4/0.5); `moon_bias_mult` scales the §2-L1 moon
normal_bias on `district_entered` (dense geometry needs more bias).
Machine copy: `metadata/district_lights` in `visual_quality.tres`.

| District | Accent (LUT) | energy_mult | moon_bias_mult | Rationale |
|---|---|---|---|---|
| suburbs | `#f4a35d` amber | 1.0 | 1.0 | baseline domestic warmth |
| residential | `#f4a35d` amber | 1.0 | 1.0 | twin of suburbs (byte-identical LUT) |
| park | `#f4e35d` yellow-green | 0.95 | 0.9 | open ground, fewer occluders |
| school | `#f4c95d` gold | 1.0 | 1.0 | institutional neutral |
| hospital | `#5dc8f4` cyan | 0.9 | 1.0 | clinical dim; cyan stays in grade, lamps dimmer |
| gas_station | `#e85d3a` ember | 1.1 | 1.0 | electric forecourt punch |
| police | `#5d5dc8` indigo | 0.9 | 1.0 | authority-cold; sodium floods read brass but restrained |
| warehouses | `#e85d3a` ember | 1.1 | 1.2 | fog punch-through + dense geometry |
| industrial | `#e85d3a` ember | 1.15 | 1.2 | same + machinery silhouettes |
| substation | `#f4f45d` pale | 1.05 | 1.1 | fog, sparse structures |
| power_station | `#f4f45d` pale | 1.15 | 1.1 | finale presence through fog |

## 4. Particle budgets (canon: <500 concurrent)

Worst-case high: rain 300 + dust 60 + ash 80 + bursts ~50 = 490.
Worst-case low: (300+60+80)×0.35 + strobe 24 ≈ 178.

| Emitter | Scene | High | Med | Low | Notes |
|---|---|---|---|---|---|
| Rain | `scenes/vfx/vfx_rain.tscn` | 300 | 180 | 100 | `local_coords=false`, follows camera at +12 m (W7) |
| Dust / FogDrops | `scenes/vfx/vfx_dust.tscn` | 60 | 36 | 20 | second instance serves `FogDrops` slot |
| Strobe | `scenes/vfx/vfx_strobe.tscn` | 24 | 24 | 24 | one-shot, auto-free |
| Ash (existing) | `scenes/main_3d.tscn` Ash | 80 | 50 | 30 | scale via `amount_ratio` (W7); scene not owned, values only |

Mobile caps: `amount_ratio` = `particle_ratio` (1.0/0.6/0.35) +
`fixed_fps` 30 on low. Snow slot stays empty (no asset, out of scope;
`weather_vfx.gd` null-guards it).

## 5. Prop VisibilityRange LOD plan (for local agent; scenes not owned)

`GeometryInstance3D.visibility_range_begin/end/begin_margin` +
`visibility_range_fade_mode` (1 = self-fade). Streetlight poles/lamps
stay always-visible (navigation-critical + already MultiMesh-batched).

| Class | begin | end | margin | fade | Low ×0.7 |
|---|---|---|---|---|---|
| Small props (crates, bottles, glints) | 8 m | 25 m | 3 m | self | 18 m |
| Mid props (benches, fences, cones) | 15 m | 45 m | 5 m | self | 32 m |
| Trees / leaves batches | 20 m | 70 m | 8 m | self | 50 m |
| Contact-shadow blobs | 5 m | 30 m | 4 m | self | off |
| Fog cards | 8 m | 60 m | — (shader self-fade) | — | off |
| Buildings / walls | — | — | — | — | always (silhouette) |

## 6. UI transitions (all screens EXCEPT options) + parallax

Reuse only: `FadeTransition.fade_to(callable, duration)`,
`TransitionManager.fade_out/fade_in(time)`, `Routes.goto(path)`.
`settings_screen.tscn` is owned by another agent — NOT listed, do not add.

| Route / screen | Fade | Enter behavior |
|---|---|---|
| boot → menu, menu → loading → game | 0.35 / 0.5 (loading→game heavier) | panels rise 12 px + fade, 0.22 s, TRANS_CUBIC EASE_OUT |
| menu ↔ difficulty / credits / save_slots | 0.25 | same enter; back = reverse 0.18 s |
| game ↔ pause | 0.18 (TransitionManager) | instant content, fade only (keeps tactics snappy) |
| death / game_over → menu / restart | 0.6 slow | letterbox-feel: slow fade, no panel motion (solemn) |
| Overlays: inventory, skill tree, map, stats, achievements, daily, album, epilogue, lobby, tutorial, confirm_quit, NG+ | 0.22 | scale 0.98→1.0 + fade, 0.2 s, TRANS_CUBIC EASE_OUT |
| HUD elements | none | never fade gameplay HUD (visibility sim, not menus) |

Parallax (W8): add a full-rect TextureRect with the district's
`assets/textures/loading/*_loading.png` art behind menu content on
`main_menu` / `menu` / `credits` / `stats_screen`, with
`menu_parallax.gdshader`; drive `parallax` from mouse (−0.5..0.5,
×`menu_parallax` preset 1.0/0.7/0.4). Current menus are flat ColorRects,
so parallax needs that art layer first — no code change works without it.

## 7. `visual_quality.tres` schema

Base `Resource` + `metadata/*` (scriptless by scope constraint).
`metadata/schema_version=1`; `profile_desktop="high"`;
`profile_mobile="medium"`; `graphics_tier_map={low:0, medium:1, high:2}`
(Ultra tier 3 reuses `high`). `low/medium/high` dicts share 35 keys
(env, glow, fog, SSAO/SSIL/SSR/volumetric, `bg_mode`, particles,
materials, `fog_cards`, `contact_shadows`, `ui_transitions`,
`menu_parallax`); `district_lights` holds §3. Read via
`load("res://assets/config/visual_quality.tres").get_meta(preset)`.

## 8. WIRING SPEC (for the local agent — settings hookup later)

Order of application at boot: W1 preset → W2 camera attrs → stage/theme
colors → `_apply_lut` (LUT) → `_apply_postfx` (per-district bloom) →
W4/W5 materials → W7 particles. LUT + postfx stay LAST (they refine, not
replace, the preset base).

- **W1 Environment presets.** In `world_env_setup.gd._ready`, before
  `apply_for_stage`: `profile = "mobile" if OS.has_feature("mobile")
  else "desktop"`; `base = load("res://assets/env/night_environment_" +
  profile + ".tres")`; copy its keys onto `_env` (or assign a duplicate
  as the WorldEnvironment resource). DELETE the `TONE_MAPPER_AGX` line
  (GDD §11 = ACES). On `graphics_tier` change, re-apply the mapped
  `low/medium/high` dict from `visual_quality.tres` (tier 3 → high).
  Known conflict (not mine to fix): `district_scene_factory` builds a
  SECOND WorldEnvironment for procedural districts — unify on one.
- **W2 Camera attributes.** Assign `camera_attributes_night.tres` to
  `WorldEnvironment.camera_attributes`. No-op on Compatibility
  (auto-exposure is Forward+ only); the fixed `exposure_multiplier`
  1.0 + `tonemap_exposure` 1.0 ARE the working night exposure.
- **W3 Fog cards.** Instance horizontal PlaneMeshes with
  `height_fog_card.gdshader` (~0.3 m above ground, 8–20 m wide): 2–6
  per fog district (warehouses/industrial/substation/power_station),
  0–2 elsewhere (creeks/valleys only). Skip entirely on low
  (`fog_cards=false`).
- **W4 Lamp flicker + hum sync.** Assign `mat_lamp_flicker.tres` as
  `StreetlightLampsBatched.material_override` and the `Lamp` material
  in `streetlight_3d` instances; set `lit` 0/1 (tween on restore) per
  district stage. Set `StreetlightHumPool` players' `bus = &"Hum"`;
  each 0.1 s, `hum = clamp(AudioServer.get_bus_peak( hum_idx ))` →
  `hum_level` on the district's lamp material (skip sampling on low;
  leave 1.0).
- **W5 Ground + leaves.** Assign `mat_wet_asphalt.tres` to district
  `Ground` (or the `district_grading` ground material slot);
  `reflection_strength`/`wetness` from preset + weather rain strength.
  Assign `mat_foliage_sway.tres` to `TreeLeavesBatched`; scale
  `sway_strength` by `foliage_sway`. Tune `sway_top` to the leaf mesh
  (≈1.2 m street crowns).
- **W6 Contact shadows + LOD.** Stamp `contact_shadow.gdshader` quads
  (+0.02 m, footprint-scaled) per prop in `street_props` /
  `city_decorator`; gate on `contact_shadows`. Apply §5
  VisibilityRange values (×0.7 on low).
- **W7 Weather VFX.** Instance `vfx_rain.tscn` as `WeatherVFX/Rain`
  (follows camera XZ at +12 m Y) and `vfx_dust.tscn` as
  `WeatherVFX/FogDrops` + interior dust spots; trigger
  `vfx_strobe.tscn` from gameplay. Apply `amount_ratio` +
  `fixed_fps` + `ash_amount` from preset to all four emitters.
- **W8 UI transitions + parallax.** Implement §6 timings via the
  existing fade singletons. NEVER add transitions to
  `settings_screen.tscn` (other agent). Parallax needs the loading-art
  TextureRect layer first (see §6).
- **W9 ThemeProvider parity.** Add to `build_theme()`: brass 2 px
  `focus` StyleBox for Button (+ LineEdit/OptionButton), distinct
  `disabled` bg (not `btn_n` reuse), type-scale constants
  (Display 44 / Huge 30 / Title 22 / Body 16 / Small 13 / Mono 15),
  Title labels on Bebas. The two `.tres` themes are the fallback/spec
  reference, not the live path.
- **W10 District lights + moon.** Multiply `streetlight_3d`
  `_update_light` energies by `energy_mult` (§3). Set Moon
  `shadow_bias` 0.06 / `shadow_normal_bias` 1.2 (from 0.1/2.0 —
  VERIFY ON DEVICE, blind-tuned), scaled by `moon_bias_mult` on
  `district_entered`. Fix `DistrictThemes.apply_to_environment`:
  ambient 0.5 → stage canon (0.03/0.06/0.11/0.16), fog 0.005 → 0.013
  (canon band). If reviving `district_grading.gd`, rename its
  `fog_color` → `fog_light_color` (`fog_color` is not a Godot property).
- **W11 Verification.** `bash tools/check.sh --static`, the four
  headless gate scenes, `docs/shots/` before/after for env + one
  district + menu (PRODUCTION_BIBLE §7), draw-call budget check.

## 9. Files changed

New: 6 shaders, 2 env presets, 1 camera attrs, 3 materials,
`assets/config/visual_quality.tres`, 3 vfx scenes, this doc, artifact
`docs/artifacts/visual-pass/VISUAL_PASS_SUMMARY.md`. Edited:
`assets/ui/theme_tls.tres`, `data/ui/theme_main.tres`,
`default_bus_layout.tres` (+`Hum` bus). No `.gd`, no screens, no `.import`.

## 10. Validation + self-review

- `bash tools/check.sh --static`: 12/12 green. `flow_check`,
  `scene_node_check`, content validators: green. No Godot binary in
  this sandbox — engine gates must run on the owner's machine (W11).
- Scripts: 340 `.gd` files, none added/removed → parse count preserved.
- Problem 1 — `.tres` metadata has no in-repo precedent: mitigated by
  keeping values to plain Variants, single-line dicts, key-parity
  check in the validator, and duplicating every value in §2/§7.
- Problem 2 — shadow-bias + fog-height values tuned blind (no engine
  here): flagged VERIFY ON DEVICE in W10; deltas kept small and preset-
  gated so a bad value degrades one knob, not the frame.
- Problem 3 — two editors of truth (presets vs runtime `.gd` overrides):
  mitigated by W1's strict application order (preset first, LUT/postfx
  last) and by changing no live behavior until the local agent wires it —
  this pass cannot regress the current frame by itself.
