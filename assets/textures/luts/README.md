# Per-district color-grading LUTs — THE LAST STREETLIGHT

Owner: CONTENT+ASSETS agent (visual pass). 11 color-correction LUTs, one per district, in the
canon order of the city chain:

`suburbs → residential → park → school → hospital → gas_station → police → warehouses →
industrial → substation → power_station`

Each file is a Godot `Environment.color_correction` LUT, **256×16**, 8-bit sRGB PNG.
Grading intent is taken **exactly** from `docs/VISUAL_AUDIO_SPEC.md` §1, whose source of
truth is the shipped `scripts/world/district_themes.gd` `THEMES` table (accent / sky /
ambient / weather). Nothing here is invented.

## Files

| District | LUT | Mood read (spec) | Sky/ambient base | Accent (lights only) |
|---|---|---|---|---|
| suburbs | `lut_suburbs.png` | cold green-grey base; amber is the only warm note | `#0b0f0a` / `#141a12` | `#f4a35d` amber |
| residential | `lut_residential.png` | twin of suburbs — identical grade, differs only by prop density | `#0b0f0a` / `#141a12` | `#f4a35d` amber |
| park | `lut_park.png` | the one warmer, more natural green base | `#0a110a` / `#12180f` | `#f4e35d` yellow-green |
| school | `lut_school.png` | institutional cold; gold reads fluorescent, not brass | `#0b0c11` / `#14151c` | `#f4c95d` gold |
| hospital | `lut_hospital.png` | clinical cyan — warm is *absent* by design | `#0b0c11` / `#14151c` | `#5dc8f4` cyan |
| gas_station | `lut_gas_station.png` | danger-adjacent warmth, electric not cozy | `#100d0a` / `#1a140f` | `#e85d3a` ember |
| police | `lut_police.png` | authority-cold indigo; ambient stays indigo under sodium floods | `#0a0a11` / `#12121c` | `#5d5dc8` indigo |
| warehouses | `lut_warehouses.png` | ember through fog — contrast softened at range | `#100d0a` / `#1a140f` | `#e85d3a` ember |
| industrial | `lut_industrial.png` | twin of warehouses — differs by machinery silhouette | `#100d0a` / `#1a140f` | `#e85d3a` ember |
| substation | `lut_substation.png` | coldest, most desaturated — almost no chroma | `#0c0c0c` / `#161616` | `#f4f45d` pale yellow-white |
| power_station | `lut_power_station.png` | twin of substation — the finale extends it, no new palette | `#0c0c0c` / `#161616` | `#f4f45d` pale yellow-white |

Note on the two pairs of twins: `residential` is byte-identical to `suburbs`, and
`power_station` to `substation`, because the spec's differentiation lives in prop
density/silhouette and in-scene lights, **not** in grading. This is deliberate, not a
duplication bug.

## Grading rules encoded

- **Base tint** follows the district's sky/ambient hue (a *subtle* nudge of the neutral
  axis, strength 0.2–0.7), never the accent — the accent (amber/cyan/indigo/ember/gold)
  is carried by in-scene light sources, so it is **not** baked into the LUT. Spec §1:
  "never introduce a warm chroma outside the district's own accent color."
- **hospital and police are the two districts where warm is specifically absent** — their
  LUTs run cool (hospital cyan-leaning, police indigo-leaning), no brass wash.
- **Fog districts** (warehouses/industrial) additionally lift blacks slightly and raise
  the mid curve (gamma 0.92) to soften contrast at range, per spec.
- **substation/power_station** are near-neutral and the most desaturated (sat 0.58).
- Every LUT lifts black (min texel ≥ 17) and rolls the white point (max ≤ 240) so no
  `#000000` crush or `#ffffff` blowout exists anywhere in the file (spec §4 rule 6, and
  the repo-wide "no pure black/white" purity bar).

## LUT layout (Godot convention)

256 wide = **16 tiles × 16 px**. Left→right, the tile index is **blue** (0…15). Inside a
tile, **x** is **red** (0…15) and **y** is **green** (0…15). Pixel value =
`grade(red×17, green×17, blue×17)` (15×17 = 255). The neutral/identity LUT would therefore
be `(x%16×17, y×17, x//16×17)` — these files are the *graded* version of that identity
map, per district.

## Godot 4 WorldEnvironment import steps (manual)

1. Copy the desired file into the project, e.g. `res://assets/textures/luts/lut_suburbs.png`.
2. In the **FileSystem** dock, select it and, in the **Import** tab:
   - **Compress** → *Lossless*,
   - **Mipmaps** → *Generate: Disabled* (mipmapping blurs the 16-level slices),
   - **sRGB** → leave *on* (values are authored in sRGB; this is Godot's default for a
     2D color texture),
   - click **Reimport**.
3. Open the scene's **WorldEnvironment** node → its **Environment** resource → expand the
   **Adjustments** section → assign the texture to **Color Correction**. Empty = identity
   (no correction); assigning the texture enables it.
4. Verify at runtime: shadows should read the district's base tint (cold green-grey /
   blue / warm brown), blacks should sit just above pure black, and no highlight should
   clip to pure white.

Per-district swapping at runtime is **code-owned** wiring (`scripts/world/district_grading.gd`,
`DistrictThemes`), out of scope for this asset delivery — these 11 files are the graded
LUTs that wiring consumes. CODE merges this README's intent into the central docs.
