# Visual consistency of the world (Session 23, CON1)

The look of the world is held by four rules of `docs/STYLE_GUIDE.md` section 2: only the ten chromas of the palette, no pure `#000000` or `#ffffff` as a surface, no neon,
no saturated surface. This document measures the sources against them and lists what is intentional. The tables are the output of
`python tools/qa_sim/consistency_check.py` (the facade chroma is a failing gate of `tools/check.sh --static`); frames of the result are in `docs/DENSITY_MEASURED.md`.

## 1. The colours of the world scripts

92 colour literals in the scripts that build the world (`district_dressing.gd`, `district_landmark.gd`, `skyline.gd`, `street_props.gd`, `street_builder.gd`, `manhole.gd`,
`dust_motes.gd`, `rain_lens.gd`). The chroma is the spread of the largest and the smallest channel on 0..1. The median is **0.047**: the world is dark and nearly grey, tinted.
The ones above 0.25 are the accents the palette names, nothing else:

| Colour | Chroma | What it is |
|---|---|---|
| brass `#c9a24a` | 0.50 | the Keeper's light: the landmark's glowing parts, the lamp pools, the rest lantern, the lit windows (`BRASS`, `scripts/world/district_dressing.gd:38`; `GLOW_COLOR`, `scripts/world/district_landmark.gd:10`) |
| `(0.71, 0.27, 0.18)` | 0.52 | ember: the traffic cones, emissive at 0.25 so they read in the dark (`cone_mat`, `scripts/world/street_props.gd:308`) |
| `(1.00, 0.82, 0.48)`, `(1.00, 0.85, 0.55)` | 0.52, 0.45 | the warm light of a lamp bulb |
| `(0.95, 0.86, 0.62)` | 0.33 | the dust motes in a lamp's beam, 12 % opaque |

Pure white `(1, 1, 1)` appears in `district_landmark.gd` and `manhole.gd` only as the end of an alpha ramp or a gradient (the soft edge of a halo, the fade of steam), never
as an albedo; the batched litter and barrels take white as the multiplier of their per-instance colours (`LITTER_COLORS`, `BARREL_COLORS`), so what is drawn is those
colours, all dark and low in chroma. Pure black is not used by any world script.

## 2. The facade palettes

One family of hue per district, three dark colours each (`PALETTES`, `scripts/world/skyline.gd:20`), a district without an entry keeps the canon facade `#0f151d` (the school).
Chroma of each of the three colours (the canon facade is 0.05):

| District | Chroma | District | Chroma |
|---|---|---|---|
| suburbs | 0.02 0.02 0.03 | warehouses | 0.04 0.04 0.05 |
| residential | 0.03 0.04 0.04 | industrial | 0.03 0.04 0.04 |
| park | 0.04 0.05 0.05 | substation | 0.03 0.04 0.05 |
| hospital | 0.06 0.08 0.09 | power_station | 0.04 0.04 0.05 |
| gas_station | 0.03 0.04 0.05 | police | 0.07 0.09 0.11 |

The gate's limit is 0.25 (`MAX_FACADE_CHROMA`); the highest of the ten is 0.11, a blue (the police) a half of the limit.

## 3. Materials: matte by rule

Every solid is a lit `StandardMaterial3D` with roughness 0.55 to 1.0 and metallic 0 to 0.6; nothing is glossy.

| Surface | Roughness | Metallic | Where |
|---|---|---|---|
| street, sidewalk | 0.92 dry, 0.6 where damp (Session 27) | 0 | `assets/shaders/soviet_road.gdshader:61` |
| skyline blocks | 0.7 whitewash, 1.0 where it flaked (Session 27) | 0 | `assets/shaders/soviet_facade.gdshader:92` |
| landmark body | 1.0 | 0 | `scripts/world/district_landmark.gd:174` |
| crates, litter, barrels | 0.9, 0.95, 0.95 | 0 | `scripts/world/district_dressing.gd:116-119` |
| benches (street, rest spot) | 0.85 | 0 | `scripts/world/street_props.gd:302`, `scripts/world/district_dressing.gd:316` |
| street tree trunk | 0.95 | 0 | `scripts/world/street_props.gd:305` |
| bins | 0.6 | 0.5 | `scripts/world/district_dressing.gd:120` |
| hydrants | 0.55 | 0.4 | `scripts/world/district_dressing.gd:121` |
| lamp poles, manhole iron | 0.55 | 0.6 | `scripts/world/street_props.gd:252`, `scripts/world/manhole.gd:36-37` |

## 4. What is not lit, and why (intentional)

Nine places in the shipped scripts switch a material to unshaded (`SHADING_MODE_UNSHADED`): the dust motes, the burst particles, the player's dust, the windows of the
skyline and the emissive windows, the soft quads of the dressing (the lamp pools, the rest bloom, the fog), the landmark's halo, the manhole steam, and a debug box of the
interior zone that draws only when its `debug_visible` is set (it was on by default, no scene places a zone, and it is off by default now: `_QUARANTINE/scripts/world/interior_zone.gd:4`). Every one is light or atmosphere (a glow, a haze, a particle), none is a solid; a solid that was unlit would
read flat, and none is. The light of the world follows the power of the district, stage by stage (DARK, PARTIAL, STREETS, FULL):

| Element | DARK | PARTIAL | STREETS | FULL | Where |
|---|---|---|---|---|---|
| ambient energy | 0.03 | 0.06 | 0.11 | 0.16 | `_STAGE_AMBIENT`, `scripts/world/district_grading.gd:19` |
| lit share of the skyline's windows | 0.04 | 0.30 | 0.60 | 0.90 | `STAGE_LIT`, `scripts/world/skyline.gd:45` |
| landmark glow energy | 0 | 0.6 | 1.3 | 2.4 | `GLOW_BY_STAGE`, `scripts/world/district_landmark.gd:13` |
| landmark halo opacity | 0 | 0.05 | 0.10 | 0.17 (Session 27) | `HALO_BY_STAGE`, `scripts/world/district_landmark.gd:15` |
| lamp pool opacity | 0 | 0.05 | 0.11 | 0.16 | `POOL_BY_STAGE`, `scripts/world/district_dressing.gd:27` |
| ground fog opacity (fog districts) | 0.12 | 0.25 | 0.35 | 0.45 | `FOG_BY_STAGE`, `scripts/world/district_dressing.gd:34` |

All of them follow one signal (`EventBus.district_stage_changed`), so the dark-to-lit beat is one gesture across the sky, the street and the ground, not four.

## 5. What this does not prove (owner rows)

- **V-1** on-device colour: an OLED phone shows the darks differently from the desktop iGPU that the frames came from; the facade, the ground and the fog sit near black.
  Executable action: read the first district at night on a phone at its lowest and its highest brightness, and say if the silhouettes of the facades still read.
- **V-2** the AAA reference comparison: `docs/AAA_BENCHMARK.md`.
