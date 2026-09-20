# Visual pass — remaining work (post static-verifiable pass, 2026-09-21)

`docs/VISUAL_PASS.md` W1-W10 status: W1 (env presets) and W9 (ThemeProvider
focus/disabled parity) were already wired going into this pass. This pass
added one more static-verifiable item (W10's streetlight `energy_mult`,
below) and did NOT touch shader/material work, particle VFX instancing, or
anything needing a rendered frame to judge — this sandbox now has a real
Godot binary and could render, but per-district light/fog/material *quality*
is a human-eyes call, not something worth guessing at via screenshot
round-trips in an autonomous pass. Everything below is exact file paths +
intended change + the command to verify it on a real machine.

## Done this pass

- **W10 (partial): per-district streetlight energy.** `scripts/world/streetlight_3d.gd`
  now reads `visual_quality.tres`'s `metadata/district_lights[<id>].energy_mult`
  in `_ready()` and multiplies every `spot.light_energy`/`glow.light_energy`
  write (both the stage table in `_update_light` and the flicker in
  `_process`) by it. Data was already authored (§3 of VISUAL_PASS.md); this
  just wires the existing constant into the existing per-stage light code.
  No shader, no material, no new asset.

## Found, deliberately NOT touched — doc/code conflict

- **W10 (DistrictThemes ambient/fog "canon" fix).** VISUAL_PASS.md's wiring
  spec says change `district_themes.gd`'s `apply_to_environment()` ambient
  `0.5 → stage canon (0.03/0.06/0.11/0.16)` and fog `0.005 → 0.013`. But the
  actual live, stage-aware ambient system is `scripts/world_env_setup.gd`'s
  `apply_for_stage()`, whose real canon constants are `AMBIENT_DARK=0.12`,
  `AMBIENT_LIT=0.20`, `AMBIENT_FULL=0.30` (3 stage buckets, not 4) — a
  different number scale than the doc's `0.03/0.06/0.11/0.16`. Two
  independent ambient-setting code paths exist
  (`district_themes.apply_to_environment` and `world_env_setup.apply_for_stage`)
  and it's not established from static reading alone which one wins at
  runtime, or whether `district_themes.gd`'s hardcoded `0.5`/`0.005` is even
  live (could be dead-overwritten immediately after by `world_env_setup.gd`,
  matching the doc's own W1 note that `world_env_setup.gd` "overrides
  `world_env.tscn` at runtime"). Guessing a value here risks silently
  regressing the correct number. **Owner/dev-with-render-session step:**
  trace call order between `district_themes.apply_to_environment` and
  `world_env_setup.apply_for_stage` on a district transition (add a temporary
  print, or breakpoint, on each), confirm which value survives, then either
  delete the dead write or reconcile the two canon tables.

## Owner-run, needs rendering/listening to judge (not attempted)

All of these have their assets already authored and sitting unused — the
gap is wiring + a render pass to confirm the result looks/reads right, which
this pass deliberately left alone:

- **W3 Fog cards** (`assets/shaders/height_fog_card.gdshader` exists,
  unused). Instance 2-6 `PlaneMesh` quads per fog district per §3 of
  VISUAL_PASS.md; needs a look at actual fog-district geometry to place them.
- **W4 Lamp flicker + hum sync** (`assets/shaders/streetlight_flicker.gdshader`,
  `assets/env/mat_lamp_flicker.tres` exist, unused). Assign as
  `StreetlightLampsBatched.material_override`; needs on-device confirmation
  the flicker curve matches the existing code-driven `Light3D` flicker
  (`streetlight_3d.gd`'s `_process`) rather than fighting it visually.
- **W5 Ground + leaves materials** (`assets/shaders/wet_asphalt.gdshader`,
  `foliage_sway.gdshader`, `assets/env/mat_wet_asphalt.tres`,
  `mat_foliage_sway.tres` exist, unused). Assign to district `Ground` /
  `TreeLeavesBatched`; wet-asphalt reflection strength needs a render to tune
  against the actual night lighting.
- **W6 Prop LOD (`VisibilityRange`)**. §5's table (small/mid/trees/contact-
  shadow-blob/fog-card ranges) is pure numeric data and IS static-verifiable
  in principle, but this pass didn't find a single clear wiring point:
  `scripts/world/street_props.gd`/`city_decorator.gd` spawn props into
  MultiMesh batches (per the streetlight batching note already in
  `streetlight_3d.gd`), and `VisibilityRange` properties apply per-instance,
  not per-MultiMesh-item — batched props can't take per-instance LOD without
  either un-batching (draw-call regression, the opposite of what this table
  is for) or a different mechanism (e.g. `MultiMeshInstance3D` doesn't expose
  `visibility_range_*` per element). Needs a design decision before wiring,
  not just constant-plugging.
- **W7 Weather VFX instancing** (`vfx_rain.tscn`, `vfx_dust.tscn`,
  `vfx_strobe.tscn` exist, unused as `WeatherVFX` children). Particle count
  budgets (§4) are already correct in the `.tscn` files themselves — the gap
  is instancing them under `WeatherVFX` and wiring `amount_ratio`/
  `fixed_fps` from `visual_quality.tres`, then confirming on a render that
  rain/dust read correctly against the fog and don't overdraw.
- **W8 UI transition timings** (§6 table). This IS static/data (reuses only
  `FadeTransition.fade_to`, `TransitionManager.fade_out/fade_in`,
  `Routes.goto` — no shader/material), but touches ~15 screen transition call
  sites across the UI layer; left out of this pass for scope/risk reasons
  (screens are gameplay-critical UI, and a bad transition duration is a
  regression a player hits on every screen, not a cosmetic-only risk like
  the other W-items). Worth a dedicated pass with the existing UI flow gates
  (`flow_check.py`) run after every site, not folded into a "static visual
  constants" pass.
- **Menu parallax** (`assets/shaders/menu_parallax.gdshader` exists, unused).
  Blocked on its own stated prerequisite (VISUAL_PASS.md §6): current menus
  are flat `ColorRect`s with no loading-art texture layer to apply the
  shader to. Needs that art layer added first.
- **L1 Moon shadow bias** (`scenes/main_3d.tscn`'s `Moon` `DirectionalLight3D`,
  `shadow_bias=0.1`/`shadow_normal_bias=2.0`). VISUAL_PASS.md's own text
  flags the proposed `0.06`/`1.2` replacement as "blind-tuned... VERIFY ON
  DEVICE" — shadow bias is a classic acne-vs-peter-panning tradeoff that
  needs an actual rendered frame to judge, so this pass left it alone rather
  than guess at a number its own source doc doesn't trust either.

## Verification commands for the owner

```bash
bash tools/check.sh --static
python tools/flow_check.py
python tools/scene_node_check.py
```

Then, on a machine that can render (this sandbox now can — see
`docs/RELEASE_READINESS_REPORT.md` for the confirmed-working Godot path):
open `res://scenes/main_3d.tscn`, step through a district transition per
weather/stage, and eyeball the moon shadow edge, the fog card placement
candidates, and the wet-asphalt/foliage assignment before wiring W3-W5/L1.
