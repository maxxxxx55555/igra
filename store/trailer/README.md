# Trailer / viral-shorts kit — THE LAST STREETLIGHT

Owner: CONTENT+ASSETS+STORE agent. All art generated in-session 2026-09-10
(Arena image generation, text-to-image, palette-locked per `docs/STYLE_GUIDE.md`
§2: `#0c1016` `#141b24` `#c9a24a` `#aeb6bf` `#d8d2c4`; post-processed:
center-crop to exact size, pure-`#000`/`#fff` clamped to `#0a0d12`/`#f0ead9`,
verified 0 pure texels). Project-owned AI output, no third-party rights —
see `docs/ASSET_LICENSES.md` §"mega final pass: trailer graphics".
No HUD, no baked AI text (press-kit title/tagline composited in
DejaVu-Sans-Bold bone `#f2ecd9` + brass `#c9a24a`).

## Files

| File | Size | Use-cases |
|---|---|---|
| `still_first_light_1920x1080.png` | 1920×1080 | **Wow-moment 1: first streetlight restore.** Trailer opening frame / 0:03 hook; Play Store screenshot #1; Steam capsule alt; tweet/announcement hero. |
| `still_first_ending_1920x1080.png` | 1920×1080 | **Wow-moment 2: first ending (half-lit city).** Trailer finale frame; "5 endings" store bullet visual; review-kit spoiler-free ending tease. |
| `still_grid_cascade_1920x1080.png` | 1920×1080 | **Wow-moment 3: grid cascade.** Trailer mid-point drop (music swell); Shorts/TikTok cover frame; "11 connected districts" bullet visual. |
| `shorts_silhouette_1080x1920.png` | 1080×1920 | **Vertical shorts shot.** YouTube Shorts / TikTok / Reels cover + first frame; phone wallpaper freebie; Stories announcement card. |
| `presskit_1600x900.png` | 1600×900 | **Press-kit header.** Review-copy email header; press-kit deck cover; itch.io / indieDB header; festival submission banner. Title + tagline + 3 shipped district thumbs (D1 suburbs, D5 hospital, D11 power_station). |

## 2026-09-11 re-grade (visual pass)

The four mood stills were re-graded with the per-district color-correction LUTs shipped in
`assets/textures/luts/` (VISUAL_AUDIO_SPEC §1): `still_first_light` → `lut_suburbs`
(first streetlight), `still_first_ending` → `lut_suburbs` (warm-dim ending), 
`still_grid_cascade` → `lut_power_station` (finale neutral + pale gold), 
`shorts_silhouette` → `lut_suburbs` (cold silhouette + amber). Applied as a luma-mix
(strength 0.55): district tint in the shadows, warm practicals preserved, then re-clamped
to [10,240] — every still remains palette-pure (0 pure `#000`/`#fff` texels, min ≥ 18,
max ≤ 239). `presskit_1600x900.png` is a title+tagline composite over three per-district
thumbs, not a single-mood still — left untouched rather than mis-graded by one LUT.

## 2026-09-12 finale hero shots (full post-fx stack)

Four new masters, generated in-session (Arena image generation, text-to-image,
palette-locked per `docs/STYLE_GUIDE.md` §2) and finished with the FULL cinematic
stack: district LUT (trilinear, 0.55 mix — same recipe as the 2026-09-11 re-grade)
+ bloom + vignette + chroma + film grain, then clamped to [10,240] (0 pure
`#000`/`#fff` texels by construction). Project-owned AI output, no third-party
rights — license rows drafted in `docs/LEDGER_FINALE.md` §F-LIC for the docs owner
(this agent may not edit `docs/ASSET_LICENSES.md`). No HUD, no baked text.

| File | Size | Stack (exact — CODE can reproduce in Godot) |
|---|---|---|
| `hero_first_restore_1920x1080.png` | 1920×1080 | **Shot A: first streetlight restore.** `lut_suburbs` @0.55 + bloom 0.30 (hero-strong) + vignette 0.50 `#0c1016` + chroma 0.75px + grain 0.10. Trailer 0:03 hook / screenshot #1. |
| `hero_grid_cascade_1920x1080.png` | 1920×1080 | **Shot B: grid cascade.** `lut_power_station` @0.55 + bloom 0.30 + vignette 0.60 (hero-strong) + chroma 0.75px + grain 0.12. Trailer mid-point drop / Shorts cover. |
| `hero_reactor_room_1920x1080.png` | 1920×1080 | **Shot C: finale reactor room.** `lut_power_station` @0.55 + bloom 0.30 + vignette 0.55 + chroma 0.75px + grain 0.12 (hero-strong). Gold comes from in-scene practicals (canon: LUTs never bake the accent); review-kit / ending-tease. Spoiler-safe: machine hall only, no ending text. |
| `hero_shorts_cut_1080x1920.png` | 1080×1920 | **Vertical shorts cut** (Shot A composition, taller frame). Same stack as Shot A. Shorts/TikTok/Reels cover + first frame. |

Godot mapping for the stack values: LUT → `Environment.color_correction` (import
per `assets/textures/luts/README.md`); bloom → `glow_enabled/bloom/intensity 0.6/
strength 1.0/hdr_threshold 1.0`; vignette → `PostProcessOverlay.
set_vignette_strength()`; grain → `PostProcessOverlay.set_grain_intensity()`;
chroma → NEW uniform (CODE-owned). District gameplay values live in
`assets/textures/postfx/presets.json` — the hero shots use trailer-grade
overrides (bloom 0.30 / grain 0.12) disclosed in the table above, not silent
deviations. Finishing chain (numpy/PIL, seeds 101–104): Lanczos to exact canvas
→ LUT → bloom(threshold 235) → vignette (shipped shader formula) → radial chroma
→ grain (shipped add-only shader math) → clamp [10,240].

Generation prompts (recorded per `art-pipeline` — house style block in every
prompt: palette hexes, "desaturated, matte, no pure black/white, no neon, no
text/watermark", exact frame): A "single vintage streetlight igniting on empty
suburban street, dramatic backlit silhouette, lone figure with raised hand,
strong warm amber bloom halo, cold green-grey darkness, volumetric cone, wet
asphalt"; B "dark sleeping city grid from high above, wave of warm streetlights
sweeping across districts, glowing grid receding into fog, subtle vignette, no
people"; C "vast finale reactor hall, towering cylindrical core glowing warm
gold, analog dials and cable trays, lone silhouette on gantry, dust in light
shafts, filmic grain"; D vertical "same as A, tall composition, lamp at top,
cone falling onto figure, subject in middle 80%".

Sizes 3.5–4.0 MB (per-pixel grain costs ~1 MB vs the 2026-09-10 stills — accepted:
these are marketing masters, re-exported on upload, never shipped as runtime
textures). Facts: `docs/CERT_FINALE.md` §3.

## Rules

- Never recompress below q85 / never upscale — re-export from these masters.
- Shorts: pair the vertical with the 0:03 grid-cascade clip and the tagline
  "Restore the light. Every streetlight is life." (RU: «Верни свет. Каждый
  фонарь — жизнь.»).
- Spoiler policy: the ending still shows the half-lit city only — no ending
  text, no Architect reveal. Safe for pre-launch press.
