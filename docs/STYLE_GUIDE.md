# Style Guide — THE LAST STREETLIGHT (asset authoring)

Owner: CONTENT/assets agent. This guide is **derived from the shipped art** (files sampled
2026-09, listed per rule below) plus the frozen canon (`docs/GDD.md` §11,
`docs/PRODUCTION_BIBLE.md` §2–3, `docs/ART_UI_STYLE.md`). When adding any texture, icon or
audio, match this document; when this document and the art disagree, the art wins and this
file gets updated.

## 1. The one rule: temperature

Permanent night. The only visual axis is **cold darkness vs. warm light**. Every asset must
read as "unlit" by default and may only gain warmth from an in-world light source
(flashlight/streetlight brass). Sampled proof: `assets/textures/loading/residential_loading.png`
— five near-black panel-block silhouettes (#0c1016-ish sky), one streetlight with a warm
`#c9a24a` cone. Nothing else in the frame is warm.

## 2. Palette (only these chromas)

| Token | Hex | Sampled in |
|---|---|---|
| bg-deep | `#0c1016` | loading skies, crest fill |
| panel | `#141b24` | crest badge fill, UI |
| panel-edge | `#2a3340` | borders |
| brass | `#c9a24a` | crest ring, battery body, streetlight cone |
| brass-dim | `#8a7338` | inactive accents |
| ember | `#b4452f` | danger only |
| steel | `#aeb6bf` | metal caps, line art |
| bone | `#d8d2c4` | brightest line art (crest windows) |
| stamina | `#5f8a4e` | stamina only |
| teal | `#4a9ab5` | info only |

Banned everywhere (art included): pure `#000000`/`#ffffff`, neon, saturation > ~40% on
surfaces (> 60% on small accents). Darkest texel in sampled tiles ≈ `#101418`, brightest
≈ `#d8d2c4` line art.

## 3. Texture classes (sampled conventions)

| Class | Path pattern | Size | Convention (sampled file) |
|---|---|---|---|
| Ground/wall tile, dark | `tiles/<district>_floor.png`, `_wall.png` | 256² seamless | `residential_floor.png`: desaturated plank rows, matte, no specular, no grain speckle; `residential_wall.png`: blue-grey running-bond brick, mortar lines ≈ `#2a3340` |
| Ground/wall tile, lit | `tiles/<district>_*_lit.png` | 256² seamless | `suburbs_floor_lit.png` vs `suburbs_floor.png`: **same pattern, subtle warm lift** — no new geometry, no bright pools; the lit twin is the dark twin raised ~10–15% toward brass, as if ambient streetlight now reaches it |
| Item icon | `items/<item>.png` | 128² RGBA | `battery.png`: flat fill shapes, ~4px dark outline, brass/steel/bone accents, transparent bg, single soft vertical sheen, no gradients-on-icons ban applies to UI chrome only — items may use 2–3 flat tones |
| District crest | `crests/crest_<district>_96.png` | 96² RGBA | `crest_residential_96.png`: circular brass ring, panel fill, bone line-art pictogram, at most ONE brass-filled element |
| Loading art | `loading/<district>_loading.png` | ~1024×600 | flat silhouettes on bg-deep, one warm light source max |
| Surface/prop | `surfaces/<prop>_512.png` | 512² seamless | matte, same desaturation as tiles |
| FX sprite | `fx/*.png` | 64² RGBA | soft alpha ≤ 235 |

Budgets (PRODUCTION_BIBLE §4): hero ≤2048², props ≤512² (~500 KB), tiles 256². Skip
per-pixel grain on generated PNGs (it murders compression); use low-frequency blotches
(sampled tiles use exactly this).

## 4. Lighting numbers for "lit" variants

Stage ambient energy (canon, `district_grading.gd`): DARK 0.03 → PARTIAL 0.06 → STREETS
0.11 → FULL 0.16. A `_lit` tile twin should look like the dark tile viewed at STREETS–FULL:
multiply luminance ≈ ×1.35–1.5 and blend 10–20% toward `#c9a24a`, keep the darkest texel
above `#131a20`. Never repaint geometry; the pair must diff as light only.

### 4.1 Numeric acceptance test for a `_lit` twin (added with the school pass)

Measure before committing (Pillow + numpy, luminance = 0.2126R + 0.7152G + 0.0722B):

| Metric | Target | Shipped reference values |
|---|---|---|
| Luminance lift `mean(lit)/mean(dark)` | 1.35–1.50 | school pair 1.42 |
| Geometry correlation (Pearson on luminance, dark vs lit) | ≥ 0.85 | suburbs 0.999, park wall 0.930, school 0.943 / 0.895 |
| Warmth `mean(R−B)` | positive, +15…+40 (dark twins are −10…−15) | park lit +23, school lit +24 / +32 |
| Palette clamp | min texel ≥ 19, max ≤ 240 | school 19..239 |
| Seam delta (mean abs diff of wrapping edge rows/cols) | within ±30% of the dark twin's | school 3.4 vs 3.8, 4.4 vs 3.1 |

If an AI generation overshoots the lift (they usually do, ×2 or more), rescale the whole
image so the mean luminance hits `mean(dark) × 1.42`, then wrap-blend an 8 px border to
restore the seam, then clamp the palette — in that order. The same wrap-blend applies to new
`surfaces/*_512.png` prop faces that need to tile.

## 5. Audio style (summary; canon in PRODUCTION_BIBLE §3, AUDIO_LOUDNESS.md)

- Ambience beds: 36 s seamless loops, −18 LUFS, true peak ≤ −1.5 dBFS, OGG q4 mono;
  district detail one-shots 25–324 KB, layered at −20 dB (`district_atmosphere.gd`).
- District music themes: slow generative pads; canon params in `tools/gen_audio.py`
  DISTRICTS (e.g. residential = major scale, 80 bpm, root MIDI 62, 14 bars ≈ 42 s).
- "Lit" audio twins (e.g. `suburbs_lit.ogg`) = the dark bed re-voiced warmer (raise the
  pad, soften the drone) — same rule as lit tiles: same material, warmer light.

## 6. Generating new art (AI or sourced)

1. Prompt must contain: palette hexes, "desaturated, matte, no pure black/white, no neon,
   no text/watermark", exact size, "seamless tileable" for tiles, and for lit twins
   "identical geometry to the reference, warm sodium-light lift only".
2. Pass the dark twin as reference image whenever one exists.
3. Post-process: downscale to the class size (256/512/96/128), strip alpha where the class
   is opaque, verify ≤ ~500 KB.
4. Record origin + license + attribution in `docs/ASSET_LICENSES.md` before committing
   (Play Store compliance). Sourced assets: CC0/CC-BY only.

## 7. Naming

`<district>_<surface>[_lit].png`, `crest_<district>_96.png`, `<district>_loading.png`,
`<district>_<detail>.ogg` for ambience one-shots, `<district>_dark|_lit.ogg` for beds.
Lowercase snake_case, no spaces, no version suffixes in shipped paths.
