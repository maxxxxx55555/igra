# District signatures (Session 23, D1.5)

The eleven districts share one street grid, one set of prop seeds and one lighting model (the district scenes differ in loot, doors, quests and monsters, not in
streets), so the identity of a district cannot come from its layout. It comes from five things the player sees or hears: the **landmark** on the horizon, the
**facade palette** of the skyline ring, the **dressing kit** between the streets, the **mood** of the light and the weather, and the **sound beds**. This
document lists each, and says which are unique to a district and which are shared. A shared one is an honest row, never a claim.

## 1. The table

| District | Landmark (`scripts/world/district_landmark.gd`) | Facade palette, first colour, chroma | Mood: ambient, accent, weather (`scripts/world/district_themes.gd`) | Dressing signature | Dark bed, lit bed, detail loops |
|---|---|---|---|---|---|
| suburbs | water tower, lit ring of the tank | `#141917`, 0.02 (green-grey) | `#141a12`, `#f4a35d`, clear | leaves 6, litter 6 | `suburbs_dark/lit.ogg`; dog bark, porch creak, wind in leaves |
| residential | apartment tower, three lit floors, mast light | `#17171e`, 0.03 (violet-grey) | `#141a12`, `#f4a35d`, clear | litter 8, bins 2 | `residential_dark/lit.ogg`; pipe creak, television murmur, window rattle |
| park | ferris wheel (a lit ring) | `#101a15`, 0.04 (green) | `#12180f`, `#f4e35d`, clear | leaves 12, almost no litter | `park_dark/lit.ogg`; leaves skitter, branch snap, bare trees, distant city hum |
| school | clock tower | the canon facade `#0f151d` | `#14151c`, `#f4c95d`, clear | crates 2, litter 8 | `school_dark/lit.ogg`; bell echo, locker slam, chalk scratch, desk scrape |
| hospital | tower with a lit cross and a helipad | `#101a20`, 0.06 (teal) | `#14151c`, `#5dc8f4`, clear | bins 3, no leaves | `hospital_dark/lit.ogg`; monitor beep, gurney wheels, PA mumble, elevator |
| gas_station | price pylon and a canopy | `#1b1613`, 0.03 (brown) | `#1a140f`, `#e85d3a`, clear | barrels 2, puddles 3 | `gas_station_dark/lit.ogg`; sign buzz, pump hum, gravel crunch, a car passing |
| police | radio mast and the station | `#0e1320`, 0.07 (blue) | `#12121c`, `#5d5dc8`, clear | crates 2, barrel 1 | `police_dark/lit.ogg`; radio static, siren tail, boots on concrete |
| warehouses | gantry crane | `#1d1514`, 0.04 (rust) | `#1a140f`, `#e85d3a`, **fog** | crates 4, barrels 2, **ground fog** | `warehouses_dark/lit.ogg`; metal creak, chain rattle, forklift, cargo impact |
| industrial | smokestacks | `#1c1715`, 0.03 (soot) | `#1a140f`, `#e85d3a`, **fog** | barrels 4, **ground fog** | `industrial_dark/lit.ogg`; machinery drone, pipe hiss, steam vent, vent rattle |
| substation | pylon and two transformers | `#14181c`, 0.03 (steel) | `#161616`, `#f4f45d`, **fog** | sparse, **ground fog** | `substation_dark/lit.ogg`; transformer buzz, arc crackle, cable hum |
| power_station | two cooling towers and a stack | `#15191e`, 0.04 (steel blue) | `#161616`, `#f4f45d`, **fog** | crates 2, barrels 2, **ground fog** | `power_station_dark/lit.ogg`; generator thrum, HV whine, cooling fan, breaker clunk |

Sources: `PARTS` (`scripts/world/district_landmark.gd:24`), `PALETTES` (`scripts/world/skyline.gd:20`), `THEMES` (`scripts/world/district_themes.gd`), `KIT`
(`scripts/world/district_dressing.gd:44`), `AMBIENCE_DARK_BY_DISTRICT` (`scripts/systems/music_manager.gd:68`), `AMBIENCE_LIT_BY_DISTRICT` (`scripts/systems/music_manager.gd:82`) and `DETAIL_BEDS`
(`scripts/world/district_atmosphere.gd:17`). The chroma is the spread of the largest and the smallest channel of the colour on 0..1; no colour of any palette is over 0.11
(`python tools/qa_sim/consistency_check.py`, held by `tools/check.sh --static`).

## 2. Which elements are unique

| Element | Unique to a district | Shared | Verdict |
|---|---|---|---|
| Landmark | 11 of 11: eleven different silhouettes of primitive meshes behind the skyline, each dark at DARK and a silhouette against a halo at FULL | none | **unique** |
| Facade palette | 11 of 11 (ten tints and the neutral canon of the school) | none | **unique**, but subtle: the colours are dark and low in chroma by the style guide, the spread is in `docs/DENSITY_MEASURED.md` |
| Sound beds | 22 of 22 bed files are different files (the md5 of each differs) and the 40 detail loops are named for their district | none | **unique** by file; all are synthesized loops (`docs/CERT_AUDIO.md`), a composed replacement is an upgrade the owner may choose (`docs/MUSIC_BRIEF.md`) |
| Dressing | the kit counts differ, so a park is leaves and a warehouse crates; the fog is in four districts only | the meshes and the colours of crates, barrels, bins and hydrants are the same in every district | **partly unique** |
| Light and weather mood | park, school, hospital, gas_station, police: 5 of 11 | suburbs and residential have one theme, warehouses and industrial one, substation and power_station one: 6 districts in 3 pairs | **8 moods for 11 districts** |
| Layout | none | the street grid and the prop seeds of all eleven | shared by design |

## 3. Owner rows (spec for the missing signatures)

- **S-1, the three pairs of the mood** (suburbs and residential, warehouses and industrial, substation and power_station): a per-district grade so that the pair
  differs at a glance. Spec, each a value of `THEMES` and no code: residential ambient `#16151c` with the accent `#e9b36a` (a violet-grey room light against the
  suburbs' green); industrial ambient `#1c130e` (a soot-orange cast against the warehouses' brown); power_station ambient `#14181c` (a blue steel against the
  substation's neutral grey). It is not changed in this pass because the accent is also the colour of the district on the map (`get_district_color`, `scripts/ui/minimap.gd:295`),
  and the owner should see the three pairs on a phone before the map changes colour.
- **S-2, god rays through windows.** A shaft of additive quads in front of every lit window is a draw-call and a fill-rate cost on a phone (`docs/VFX_BUDGET.md`);
  the volumetric fog of the engine is not available in the compatibility renderer the game ships with. A baked shaft per landmark (3 quads) is the cheapest first step: owner decision.
- **S-3, surfaces of wood, grass, gravel and tile.** The footsteps read the surface from the metadata `surface` of the collision shape under the foot
  (`docs/AUDIO_CONSISTENCY.md`); the road strips (asphalt), the sidewalks (concrete) and the manhole covers (metal) are tagged, no shipped floor carries the other four.
  Spec: tag the park's paths (grass), the school's and the hospital's floors (tile) and the gas station's forecourt (gravel) when their interiors exist.
- **S-4, props with a district's own materials.** The crates, barrels, bins and hydrants share their meshes and colours; a hospital bin, a police barrier and a
  school bench are art work, not code.

## 4. The manholes and the fog

Every district holds up to two iron covers in the roads round the middle block, with a thread of steam (`MANHOLES`, `scripts/world/district_dressing.gd:20`); the check
MANH1 counts them in the eleven districts. The four fog districts (the weather `fog` of the theme) get three drifting cards of ground fog at the Medium tier and above, thin
in the dark and thick at full power (`FOG_BY_STAGE`, `scripts/world/district_dressing.gd:34`); the check FOG1 holds the districts, the tier and the cards.
