# Cinematic post-fx presets — THE LAST STREETLIGHT

Owner: CONTENT+ASSETS agent (preset DATA only). All wiring is CODE-owned.
`presets.json` v1, 2026-09-12: one conservative filmic preset per district
(11/11), in canon city-chain order. Grading intent follows
`docs/VISUAL_AUDIO_SPEC.md` §1 and the shipped per-district LUTs in
`assets/textures/luts/` — this layer adds **bloom + vignette + chromatic
aberration + film grain** on top of the LUT, lifting the look from "good" to
"filmic" without ever distracting from gameplay.

## Design rules (why the numbers are what they are)

- **Subtle everywhere.** Strongest bloom in the table is 0.35 (fog districts
  only), strongest vignette 0.60 (police only), grain stays inside the GDD
  §11.4 band 0.08–0.12, chroma never exceeds 1.0 px at 1080p. Nothing here
  should be *noticed* — only felt.
- **Vignette color is `#0c1016` (bg-deep) for every district**, per GDD §11.2
  and the shipped `post_process_overlay.gd` vignette shader (`BG_DEEP`
  constant). Per-district vignette colors were cut deliberately (`yagni`):
  tinting the vignette per district would fight the LUT, which already owns
  per-district color. The JSON still carries a `color` field per district so
  the schema matches the brief — all eleven read `#0c1016`.
- **Warm-absent districts stay cold.** hospital (lowest bloom 0.12) and
  police/school (0.15) bloom less than ember districts — clinical cyan and
  authority indigo must never pick up a brass wash from the glow.
- **Fog districts bloom and grain more** (warehouses/industrial 0.35/0.12):
  ember-through-fog reads as halation, which is exactly what bloom + grain
  simulate. substation/power_station sit one step lower (0.30) — coldest,
  most desaturated, almost no chroma to aberrate.
- **Twins stay twins.** residential=suburbs, industrial=warehouses,
  power_station=substation — same rule as the LUTs: differentiation lives in
  props/silhouette, not in grading.
- Verified: full-strength stack (bloom 0.35, vignette 0.60, chroma 1.0 px,
  grain 0.12) simulated over the palette-locked trailer base keeps the image
  readable and produces **zero pure-white texels** — see
  `docs/CERT_FINALE.md` §2 for the numbers.

## CODE wiring (advisory — CODE owns all implementation)

Ship-shape consumers already exist for 3 of the 4 layers:

1. **Bloom → `WorldEnvironment` Environment glow** (`scenes/environment/world_env.tscn`
   `env_night`, currently no glow keys). Per district, set:
   `glow_enabled = true`, `glow_bloom = <bloom>`, `glow_intensity = 0.6`,
   `glow_strength = 1.0`, `glow_hdr_threshold = 1.0` (property names per the
   Godot 4 Environment Inspector — confirm spelling in-editor when wiring).
   Suggested switch point: `district_grading.gd` `_apply()`, next to the fog
   keys it already drives. Leave blend mode / HDR scale / luminance cap at
   defaults.
2. **Vignette → `PostProcessOverlay.set_vignette_strength(strength)`**
   (shipped; clamps 0.0–0.7 — every preset is inside the clamp). Color stays
   the shipped `#0c1016`; no shader change needed.
3. **Grain → `PostProcessOverlay.set_grain_intensity(intensity)`** (shipped;
   clamps 0.0–0.15 — every preset is inside the clamp and the GDD §11.4
   8–12% band). No shader change needed.
4. **Chroma → NEW, no shipped consumer.** Suggested: one `amount_px_1080p`
   uniform on a fullscreen pass (same CanvasLayer family as the grain /
   vignette overlays), radial RGB split scaled by `viewport_height / 1080`.
   At ≤1.0 px this is sub-visible except on hard highlight edges — keep it
   last in the chain so it aberrates the glow, not the raw frame.

Recommended stack order: district LUT (`color_correction`) → tonemap (shipped:
filmic, exposure 0.9) → bloom → vignette → chroma → grain (grain last, so it
grains the whole graded frame like film).

Suggested call shape (pseudocode, CODE to implement for real):
`PostProcessOverlay.apply_preset(Presets.for_district(id))` reading this
JSON at boot; re-apply on `DistrictThemes.theme_changed` alongside the LUT
swap. No new autoloads, no new buses, no scene changes required for layers
1–3.

## Files

| File | What |
|---|---|
| `presets.json` | 11 district presets: bloom/vignette/chroma/grain. |
| `README.md` | This file. |
