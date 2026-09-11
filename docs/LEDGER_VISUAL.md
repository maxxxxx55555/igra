# LEDGER_VISUAL.md — visual 100/100 pass, attempt + delivery log (2026-09-11)

Owner: CONTENT+ASSETS agent. This file is the ONLY ledger for visual work. One row per
attempt/delivery step; every claim points at a verifiable artifact (file on disk, committed
PNG, or tool output quoted here). No fabricated entries. CODE merges this + CERT_VISUAL.md
into the central docs later.

Skills applied this pass: `asset_pipeline.md` (palette lock `#0c1016 #141b24 #c9a24a
#aeb6bf #d8d2c4`, deterministic PIL/numpy pipeline, no per-pixel grain on store canvases),
`art-pipeline` (AI image gen for store art, matching the 2026-09-10 trailer lineage),
`yagni` (cut the RU companion set, cut optional keeper/mystery shots beyond the 8, cut
presskit re-grade, cut programmatic bloom beyond the prompt), `self-commit` (one block =
one commit + push). NOT used: `godot-gates` (NEVER-GODOT standing — no engine in this
sandbox; correctness proven by PNG decode + pixel math), `council`, `ponytail-audit`.

## L1 — canon read (TASK 1–4 pre-work)

Read `docs/VISUAL_AUDIO_SPEC.md` (the controlling spec) and its source of truth
`scripts/world/district_themes.gd` `THEMES` — exact sky/ambient/accent per district used to
derive each LUT's tint. Read `store/screenshot-plan-detailed.md` (§0 controls, §3 recipes,
§7 touch-HUD rules) and `docs/STYLE_GUIDE.md` (palette tokens, `_lit` acceptance test).
Key decisions: the parenthetical "power_station warm gold" in the task prompt is superseded
by the spec — power_station = substation's neutral-desaturated twin, pale-yellow accent
`#f4f45d` only; suburbs = cold **green-grey** (spec), not blue. RESULT: all 11 LUTs follow
the spec exactly, not the shorthand.

## L2 — 11 per-district LUTs (TASK 1, DELIVERED 11/11)

Generated `assets/textures/luts/lut_<district>.png` (256×16, sRGB PNG) from a deterministic
numpy/PIL transform: per-channel gains nudge the neutral axis toward the district's
ambient hue (strength 0.2–0.7), luma-preserving desaturation (0.58–0.90), gamma 0.92 on the
two fog districts, black lift + white rolloff so the file itself carries no pure `#000`/`#fff`.
Twin districts share identical params → byte-identical LUTs (suburbs≡residential,
warehouses≡industrial, substation≡power_station). Self-check at generation: 0 monotonicity
defects (row-segment + column), min 17–19, max ≤ 240. First generation clipped a channel to
255 on the warm/cool districts (gain > 1 before remap); fixed by capping the gain vector at
its max channel (hue ratios preserved) — final files clip nothing. `README.md` in the same
dir documents the layout + Godot WorldEnvironment import steps. Committed `f2b32e5`.

## L3 — 8 Play-Store screenshots (TASK 2, DELIVERED 8/8)

Seven environment frames produced via Arena image generation (palette-locked prompts:
permanent night, one warm practical, "Playdead Limbo/Inside grade", no text/UI/HUD), then
post-processed deterministically: fit to 1920×1080 → district LUT as a **luma-mix**
(strength 0.6: district tint in the shadows, warm practicals preserved — a full-strength
LUT washed the money-shot brass toward olive, measured, then corrected) → bloom → vignette
(0.45) → clamp [16,240]. Shot 8 (City Map) is a programmatic composite of the repo's real
`assets/textures/maps/city_overview_1024.png` + the 11 district crests + DejaVuSans-Bold
labels + 3 stage dots per row (all FULL = green), palette-clamped — no AI text
hallucination risk. Three touch-HUD shots (P1/P2/P3) composite the repo's real touch
sprites (`assets/textures/touch/touch_joy_base_256.png`, `_knob`, `touch_interact_128.png`,
`touch_back_128.png`, `touch_pause_128.png`) + programmatic HP/stamina/battery bars, then
the 20:9 content (1920×864) is centered in 1920×1080 and letterboxed with flat `#0c1016`
(pad, never crop, per plan §7). All 8 verified palette-pure (0 pure black/white, max ≤ 240,
mean saturation ≤ 24). Files + upload order documented in `store/screenshots/README.md`.
Committed `bbd3ad4`.

## L4 — trailer key-art re-grade (TASK 3, 4 stills re-graded)

Re-graded in place: `still_first_light` → `lut_suburbs`, `still_first_ending` →
`lut_suburbs`, `still_grid_cascade` → `lut_power_station`, `shorts_silhouette` →
`lut_suburbs` — luma-mix strength 0.55, re-clamped [10,240]. Measured mean shift confirms a
subtle, directionally-correct tint (e.g. first_light .14/.15/.15 → .16/.18/.17 = green-grey
shadows, warm highlights preserved). `presskit_1600x900.png` is a title+tagline composite
over three per-district thumbs — left untouched rather than mis-graded by a single LUT
(yagni). Originals recoverable from git history. README updated. Committed `0ed8ec6`.

## L5 — static certification (TASK 4, 0 defects)

`/tmp/tls_visual/verify.py` (exit 0) re-ran every check against the committed artifacts:
LUT dims/purity/mono, screenshot dims/purity/saturation/letterbox/size, trailer dims/purity.
**Defects: 0** — full tables in `docs/CERT_VISUAL.md`. Origin note (no ASSET_LICENSES.md
write — forbidden zone for this agent, CODE merges): screenshots and re-graded stills are
project-owned AI output (Arena image generation) composited with repo-owned art; no
third-party rights; LUTs are deterministic program output. Committed with this file.

## Commits this pass (branch `arena/01a0902d-igra`, pushed to origin)

| Hash | Subject |
|---|---|
| `f2b32e5` | visual: add 11 per-district color-grading LUTs (256x16) + WorldEnvironment import README |
| `bbd3ad4` | visual: add 8 Play-Store screenshots (1920x1080, 3 touch-HUD letterboxed) per screenshot plan |
| `0ed8ec6` | visual: re-grade trailer mood stills with per-district LUTs (luma-mix); presskit left as composite |
| *(docs)* | visual: LEDGER_VISUAL + CERT_VISUAL (static checks, 0 defects) |
