# Visual consistency report — MEGA FINAL PASS (2026-09-13)

Independent review agent. All numbers below were computed with Pillow 12.2.0 + numpy
against the files on disk; nothing is estimated.

**Headline: `LUT 11/11 | presets 0 out-of-range | palette 0 outliers | cards 4 distinct of 22`**

## 1. LUT coverage — 11/11

`scripts/world_env_setup.gd::_apply_lut` builds `res://assets/textures/luts/lut_<id>.png`
where `<id>` is the `id` field of each `data/districts/*.tres`. All 11 districts
(suburbs, residential, park, school, hospital, gas_station, police, warehouses, industrial,
substation, power_station) have a matching LUT on disk. No district falls back silently.

## 2. Post-FX presets — 0 out of range

`assets/textures/postfx/presets.json` carries a row for all 11 districts. Authored ranges
against the clamps enforced in `scripts/post_process_overlay.gd`:

| Knob | Authored | Clamp | Headroom |
|---|---|---|---|
| grain | 0.09–0.12 | 0.0–0.15 | yes |
| vignette | 0.45–0.60 | 0.0–0.70 | yes |
| chroma (px @1080p) | 0.5–1.0 | 0.0–3.0 | yes |

Every value is finite, non-negative and inside its clamp, so no authored intent is being
silently clamped away.

## 3. Palette family — 0 outliers

Canon taken from `docs/STYLE_GUIDE.md` §2 (bg-deep `#0c1016`, panel `#141b24`, panel-edge
`#2a3340`, brass `#c9a24a`, brass-dim `#8a7338`, ember `#b4452f`, steel `#aeb6bf`, bone
`#d8d2c4`, stamina `#5f8a4e`, teal `#4a9ab5`) plus the per-district accents that
`docs/VISUAL_AUDIO_SPEC.md` §1 documents as deliberate rule-breaks (hospital cyan
`#5dc8f4`, police indigo `#5d5dc8`).

Method: average colour plus top-5 quantised dominant colours for 100 files — 31 badges,
22 cards, 47 icons. Every dominant swatch covering ≥8% of pixels at saturation ≥0.15 was
converted to HSV and measured by circular hue distance to the nearest canon hue; near-neutral
greys were excluded because hue is noise there. 223 qualifying swatches, outlier threshold
40°.

**Result: 0 outliers.** Many are exact matches (badge medal gold is literally `#c9a24a`;
the siren icon is literally `#b4452f`). No green/magenta/neon leakage. The generator
pipeline's rule that prompts must carry palette hexes (STYLE_GUIDE §6) is holding.

## 4. Card duplicates — the one real defect

Average-hash (8×8, Hamming) and mean-absolute-difference on 32×32 greyscale, all
C(11,2)=55 unlocked pairs:

| Cluster | Hamming | MAD |
|---|---|---|
| suburbs / residential / park | 0 | 1.06–2.93 |
| school / hospital / gas_station / police | 0–1 | 2.1–6.2 |
| warehouses / industrial | 0 | 1.07 |
| substation / power_station | 0 | 1.06 |

Nearest cross-cluster pair (hospital/industrial) is Hamming 9 / MAD 16.1 — clean separation,
so these are four genuine clusters rather than a threshold artifact. Locked variants are
fine: each matches only its own unlocked twin, differing by darkening rather than structure.

**11 districts are represented by 4 photographs; all 22 card files reduce to those 4.**
This is materially worse than the "4 of 22" previously recorded, and `KNOWN_ISSUES.md` has
been corrected accordingly. Seven districts need new photography. Not fixable in code.

## 5. Badge legibility at 48px — 0/31 flagged

All 31 badges downscaled (LANCZOS) to the 48×48 the achievement screen renders. Luminance
std-dev 30.3–54.8, corner-vs-centre contrast 36.3–81.6, spread 135–239. Nothing approaches
the mush thresholds (std < 20 or contrast < 15). Weakest three, still comfortably
acceptable: `badge_ach_19` (std 30.3), `badge_ach_district_suburbs` (std 32.2),
`badge_ach_20` (std 32.3).

## Fix first

1. Re-source distinct photography for the seven districts that currently borrow another
   district's base image. This is the only real defect this audit found, and it is an art
   task, not a code task.
2. Nothing else. LUTs, presets, palette family and badge legibility all measured clean —
   re-run this audit after the card fix to confirm new photography still lands inside the
   hue-family bounds established in §3.
