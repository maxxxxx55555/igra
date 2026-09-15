# Artifact — visual pass summary (2026-09-15)

AAA environment/material/UI pass with DESKTOP + MOBILE profiles for the
Godot 4.7 nocturnal survival game. Full detail: `docs/VISUAL_PASS.md`.

## Delivered (21 files, owned paths only)

- 6 shaders: lamp flicker (hum-synced), wet asphalt (Compat SSR
  substitute), foliage sway, fog cards (volumetric substitute), contact
  shadows (SSAO substitute), menu parallax.
- 2 Environment presets (ACES, tuned glow, exp+height fog, SSAO
  desktop-only) + night camera attributes (night-safe AE limits) +
  3 tuned ShaderMaterials.
- `assets/config/visual_quality.tres`: low/medium/high × 35 keys +
  11-district light table; desktop→high, mobile→medium.
- 3 VFX scenes: rain 300 / dust 60 / strobe 24; worst case 490 < 500 budget.
- Themes: type scale 44/30/22/16/13/mono, focus outlines, disabled
  states, corner-radius canon fix (8→0). `Hum` audio bus appended.
- `docs/VISUAL_PASS.md`: before/after table + W1–W11 wiring spec for the
  local/settings agent. Transitions specified for all screens EXCEPT
  options (other agent).

## Key decisions

- GL Compatibility on both profiles → SSIL/SSR/volumetric/AE are
  declared no-ops with working shader substitutes (renderer truth table
  in the doc). ACES per GDD §11 (live AGX override contradicts GDD).
- No live behavior changes until wired: runtime `.gd` still owns all
  values; this pass cannot regress the current frame by itself.

## Gates

`tools/check.sh --static` 12/12 green; custom structural validator green
(19 files); 340 scripts untouched (parse count preserved). Engine gates
need the owner's Godot binary (absent in this sandbox).
Commit: `feat(visual): AAA environment/material/UI pass with mobile profiles`.
