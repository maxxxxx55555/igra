# Handoff for a generator run and for the pass that integrates it (Session 24, P3)

Written by `python tools/qa_sim/gemini_handoff.py --write` from `docs/MUSIC_BRIEF.md`, `docs/MUSIC_RECIPE.md`, `docs/MUSIC_SPEC.md`, `docs/MUSIC_PROMPTS_FULL.md` and `docs/CARD_ART_BRIEF.md`;
`--check` (a static gate) fails when a source moved or a file appeared on disk. **Nothing here was made**: no audio, no image, no download. The tools of a generator (names, limits, the length of a take) change; what
a given product does today is UNVERIFIABLE-HERE and is the owner's to read on the day.

## 1. What is asked, and what is not

- **Asked of the generator:** audio for the tracks of section 2 and seven portrait photographs of section 3, rendered from the prompts that are already written (the music list `docs/MUSIC_PROMPTS_FULL.md`, absorbed from
  `origin/claude/keen-cori-0sc9uo`; the card prompts of `docs/CARD_ART_BRIEF.md` section 4). The generator's output is raw material: it is trimmed, graded and gated by the tools of section 4 before it is a game file.
- **Not asked, not done:** nothing is wired by this document, no binary is committed with it, and no file lands in `assets/` or `content/` until the integration checklist of section 4 has been run on it. The game runs without any of
  these files: every music path is guarded by `ResourceLoader.exists` (`scripts/systems/music_manager.gd`), and the cards exist (section 3.1). A missing track is an upgrade not made, never a hole.
- **Language:** English for every prompt (the house prompts are English; `docs/MUSIC_PROMPTS_FULL.md` has the same 69 in one list; a Russian phone copy of them is on `origin/claude/keen-cori-0sc9uo`, not absorbed).

## 2. Music

### 2.1 The house law (`docs/MUSIC_SPEC.md`)

> | Ambience/music beds loudness | −18 LUFS int., TP ≤ −1.5 dBFS | README, AUDIO_COVERAGE |
> | Stingers/SFX loudness | −14 LUFS int., TP ≤ −1.5 dBFS | AUDIO_LOUDNESS.md |

Every bed is a seamless loop of 36 s in the lit-bed brief, mono, 44.1 kHz, OGG quality 4; a take is trimmed at a zero crossing with 3 ms edge fades, loudness-normalised to the figure above, and checked against the true-peak
ceiling of -1.5 dBFS. `python tools/qa_sim/audio_loudness.py --check` reads every shipped file.

### 2.2 The 11 lit beds: all on disk (synthesized loops), a composed replacement is an upgrade

From `docs/MUSIC_BRIEF.md` (generated from `AMBIENCE_LIT_BY_DISTRICT`); the measures are of the files today. The brief and the prompt of each bed are in that document, one row per district.

| District | Target file | On disk | Length (s) | Channels, rate | LUFS | True peak (dBFS) |
|---|---|---|---|---|---|---|
| suburbs | `assets/audio/ambience/districts/suburbs_lit.ogg` | yes | 36.0 | 1, 44100 | -18.8 | -9.1 |
| residential | `assets/audio/ambience/districts/residential_lit.ogg` | yes | 36.0 | 1, 44100 | -18.1 | -4.9 |
| park | `assets/audio/ambience/districts/park_lit.ogg` | yes | 36.0 | 1, 44100 | -18.1 | -4.2 |
| school | `assets/audio/ambience/districts/school_lit.ogg` | yes | 36.0 | 1, 44100 | -18.1 | -3.9 |
| hospital | `assets/audio/ambience/districts/hospital_lit.ogg` | yes | 36.0 | 1, 44100 | -19.5 | -10.6 |
| gas_station | `assets/audio/ambience/districts/gas_station_lit.ogg` | yes | 36.0 | 1, 44100 | -18.1 | -3.5 |
| police | `assets/audio/ambience/districts/police_lit.ogg` | yes | 36.0 | 1, 44100 | -18.1 | -4.0 |
| warehouses | `assets/audio/ambience/districts/warehouses_lit.ogg` | yes | 36.0 | 1, 44100 | -18.0 | -2.7 |
| industrial | `assets/audio/ambience/districts/industrial_lit.ogg` | yes | 34.0 | 1, 44100 | -18.0 | -3.3 |
| substation | `assets/audio/ambience/districts/substation_lit.ogg` | yes | 36.0 | 1, 44100 | -18.0 | -4.3 |
| power_station | `assets/audio/ambience/districts/power_station_lit.ogg` | yes | 36.0 | 1, 44100 | -19.5 | -12.4 |

The length of 36 s is the contract; the bed that does not meet it today: `industrial` (34.0 s).
The brief's prompts end with the common line: *instrumental only, no vocals, no drums, seamless 36 s loop, mono, about -18 LUFS*.

### 2.3 The 19 tracks of the music recipe, against the disk

`docs/MUSIC_RECIPE.md` is the ordered list (2026-09-21). "On disk" is a check of `assets/audio/<target>` now; the prompt is in the section of `docs/MUSIC_PROMPTS_FULL.md` named in the last column.

| # | Target | State in the recipe | Length | On disk | Prompt section |
|---|---|---|---|---|---|
| 1 | `music/music_menu_dark.ogg` | REPLACE — retire `abandoned_hallways.mp3` from MENU once this lands | 120.000 s | **no** | 1.1 |
| 2 | `music/suburbs.ogg` | NEW | 37.333 s (14 bars @ 90 BPM) | **no** | 2.1 |
| 3 | `music/school.ogg` | NEW | 33.600 s (14 bars @ 100 BPM) | **no** | 2.4 |
| 4 | `music/hospital.ogg` | NEW | 40.000 s (10 bars @ 60 BPM) | **no** | 2.5 |
| 5 | `music/gas_station.ogg` | NEW | 34.909 s (16 bars @ 110 BPM) | **no** | 2.6 |
| 6 | `music/police.ogg` | NEW | 28.000 s (14 bars @ 120 BPM) | **no** | 2.7 |
| 7 | `music/warehouses.ogg` | NEW | 38.400 s (12 bars @ 75 BPM) | **no** | 2.8 |
| 8 | `music/substation.ogg` | NEW | 33.600 s (14 bars @ 100 BPM) | **no** | 2.10 |
| 9 | `music/power_station.ogg` | NEW | 32.000 s (14 bars @ 105 BPM) | **no** | 2.11 |
| 10 | `music/layer_threat_low.ogg` | only if forced re-render — currently SHIPPED/certified | 60.000 s | yes | 3.1 |
| 11 | `music/layer_threat_high.ogg` | only if forced re-render | 60.000 s | yes | 3.2 |
| 12 | `music/layer_action.ogg` | only if forced re-render | 60.000 s | yes | 3.3 |
| 13 | `music/music_boss_dark_p1.ogg` | NEW | 45.000 s | **no** | 4.2 |
| 14 | `music/music_boss_dark_p2.ogg` | NEW | 45.000 s | **no** | 4.3 |
| 15 | `music/music_boss_dark_p3.ogg` | NEW | 45.000 s | **no** | 4.4 |
| 16 | `ui/ui_district_restored_sting.ogg` | NEW | 2.000 s, one-shot | **no** | 5.6 |
| 17 | `music/cue_death.ogg` | NEW | 8.000 s, one-shot, zero-ended | **no** | 5.1 |
| 18 | `sfx/ui_xp_tick.wav` | NEW | 0.060 s, one-shot | **no** | 8.1 |
| 19 | `sfx/ui_heal_soft.wav` | NEW | 0.300 s, one-shot | **no** | 8.2 |

**16 of 19 targets are not on disk.** They are the true gaps. An absent file is skipped by the guards of `scripts/systems/music_manager.gd` (`ResourceLoader.exists`), and `docs/MUSIC_SPEC.md` names the fallback of each row (the menu's is `abandoned_hallways.mp3`).
The 11 beds of 2.2 are not in this list: they are upgrades.

### 2.4 After a take comes back

1. Trim to the loop length of the table at a zero crossing, 3 ms edge fades; the take must end where it began (same pad level, no reverb tail cut; crossfade the last 2 s under the first 2 s when it rings out).
2. Normalise to the house law, export OGG quality 4, mono, 44.1 kHz (`.wav` only where the target says `.wav`), save to the **exact path** of the table.
3. Add a row to `docs/ASSET_LICENSES.md` (`path | origin | license | attribution | notes`): the generator, its version, the prompt id and the licence terms of the day. A track with no row is not committed.
4. `python tools/qa_sim/audio_loudness.py --check`, then `python tools/qa_sim/music_brief.py --check`, then `bash tools/check.sh --static`.

## 3. The seven district cards

### 3.1 The state today

`docs/CARD_ART_BRIEF.md` says 11 of 11 districts have a unique card (2026-09-14): the seven below were generated in-session from the section 4 prompts, graded by `scripts/regen_cards_v2.py` (all 8 checks pass), and are in the game. What stays open there
is the licence ledgering of the seven raws ("pending with the wiring PR": the raws were not kept and cannot be re-derived without the exact model version) and the frozen suburbs and residential twin (aHash 1). A new run is a
replacement of art that works, so it is the owner's choice and not a gap.

| District | Master (1024 x 1536) | 512 twin | In game |
|---|---|---|---|
| `park` | 1024 x 1536 | 512 x 512 | 512 x 512 |
| `school` | 1024 x 1536 | 512 x 512 | 512 x 512 |
| `hospital` | 1024 x 1536 | 512 x 512 | 512 x 512 |
| `gas_station` | 1024 x 1536 | 512 x 512 | 512 x 512 |
| `police` | 1024 x 1536 | 512 x 512 | 512 x 512 |
| `warehouses` | 1024 x 1536 | 512 x 512 | 512 x 512 |
| `substation` | 1024 x 1536 | 512 x 512 | 512 x 512 |

### 3.2 Settings, seeds and what to ask for

- **Deliverable:** one raw per district, portrait 2:3, 1024 x 1536 (a generator that returns another size is cropped to 2:3 around the light and resized with LANCZOS *before* grading), PNG, no text, no watermark.
- **Common to all seven:** street level or human scale, 35 mm look, no people, one light source, fog or mist, at least a third of the frame empty, the subject filling the central horizontal band (the card shows a 230 x 84 strip).
- **Wording:** the Flux wording of section 4 (it is the wording that produced the cards on 2026-09-14: `docs/CARD_ART_BRIEF.md` section 6.3; the generator did not honour Midjourney parameters, so `--ar` and `--style` are dropped and a
  portrait sentence added). The negative prompt is used verbatim; add `human hands, feet, partial body` when people appear.
- **Seeds:** none is recorded for the raws of 2026-09-14 (the in-session generator exposes none); record the seed where a product gives one, in the licence row. The pipeline's own seed is fixed: `scripts/regen_cards_v2.py` runs with
  seed 13 and a film grain of amplitude 0.04, and two runs on the same input are byte-identical.
- **Reject before grading:** visible people or faces, more than one light source, green, magenta or neon chroma, readable text, a watermark, pure black or white, daytime or blue hour, a glossy or HDR look.

### 3.3 The seven specs

Each block is `docs/CARD_ART_BRIEF.md` section 4 for that district: the canon accent row of section 3, the four bullets, and the Flux candidates 1 and 2 with their negatives, verbatim. Candidate 3 and the Midjourney wording are in the brief.

#### 3.3.1 `park`: "the city's one living thing left"

Canon row (accent | sky and ambient | weather | rule): `#f4e35d` yellow-green | `#0a110a` / `#12180f` green-black | clear | only warm-green district — "the city's one living thing left".

- **Subject:** the park's dead carousel at night — a rusted, canopy-lopped carousel standing in a clearing, frozen pond edge or dead grass in the foreground, one old park lantern as the only light. (Canon zones: `z_carousel`, `z_pond`, `z_grove_east`.)
- **Composition:** carousel centered on a slight off-axis (rule of thirds, right), lantern at mid-height in front of the carousel casting a short warm pool; bare tree limbs frame the top; fog flattens the background to flat green-black. No benches-with-people, no playground equipment in focus.
- **Palette:** `#0a110a` [A-sky], `#12180f` [A-sky], `#272a2a` [M], `#3c3c33` [M], `#f4e35d` [A], `#8f7c55` [M dim].
- **Mood:** The park is the only place in the city that was alive, and the carousel is still faintly, wrongly waiting to spin.

Candidate 1 prompt:

```text
A single 35mm documentary photograph taken at night in an abandoned city park. A dead rusted carousel with peeling gold horses stands in a clearing, slightly right of center. One old cast-iron park lantern is the only light source, casting a short warm pool on dead grass and the frozen edge of a small pond in the foreground. Bare winter tree limbs frame the top of the frame. Heavy low fog flattens everything behind into a flat green-black distance. Muted, desaturated, matte, film grain. Colors: deep green-black shadows #0a110a and #12180f, cool grey-brown mids #272a2a and #3c3c33, one small pale yellow-green lantern glow #f4e35d. No people. No text. No watermark. No neon. No pure black or pure white.
```

Candidate 1 negative:

```text
people, human faces, crowds, cars, headlights, moon visible in sky, full moon, text, letters, watermark, logo, neon, oversaturated colors, vivid green grass, lush plants, daytime, dusk, blue hour sky, lens flare, HDR, glossy, plastic, cgi render, cartoon, illustration, painting, extra light sources, multiple lamps
```

Candidate 2 prompt:

```text
A single 35mm documentary photograph at night, low angle through the trunks of bare trees in a frozen park. Beyond the ice of a dead pond, a derelict carousel is barely visible through fog. One distant old park streetlight on a wooden post is the only light source, making a single small pool of pale yellow-green light #f4e35d on wet dead grass and ice. Deep green-black ambient #0a110a #12180f dominates the frame. Desaturated, matte, heavy film grain, one light source only.
```

Candidate 2 negative:

```text
people, faces, crowds, visible moon, stars, text, watermark, logo, neon, oversaturation, green grass, leaves on trees, daytime, blue hour, lens flare, HDR, glossy, cgi, cartoon, illustration, multiple lamps, streetlight rows, car lights
```

#### 3.3.2 `school`: "institutional cold, fluorescent memory"

Canon row (accent | sky and ambient | weather | rule): `#f4c95d` gold | `#0b0c11` / `#14151c` blue-grey | clear | fluorescent-memory gold, institutional cold.

- **Subject:** the school's locker corridor at night — the long spine of `z_corridor_lockers` — a single flickering fluorescent tube as the only light, one open classroom door at the far end. (Canon: "every zone except the yard is interior, so the flashlight is the only light" — the card shows that interior cold.)
- **Composition:** one-point perspective down the corridor; lockers in the foreground sides, the open door dead-center in the far third; the flickering tube upper-third, center; chalk dust and fine mist in the light cone; linoleum floor carries the single reflection.
- **Palette:** `#0b0c11` [A-sky], `#14151c` [A-sky], `#282c30` [M], `#3c3e40` [M], `#f4c95d` [A], `#8a755a` [M dim].
- **Mood:** The school is holding its breath — one fluorescent tube still counting the children who are no longer here.

Candidate 1 prompt:

```text
A single 35mm documentary photograph, interior of an abandoned soviet school corridor at night. One-point perspective down a long hallway. Rusted metal lockers line the foreground sides. One open classroom door is centered in the far third. A single flickering fluorescent tube is the only light source, positioned in the upper third of the frame; chalk dust and fine mist are visible inside its cone. The wet linoleum floor carries one soft reflection. Muted, desaturated, matte, heavy film grain. Colors: cold blue-grey night #0b0c11 #14151c, cool greys #282c30 #3c3e40, one sickly gold fluorescent glow #f4c95d. No people.
```

Candidate 1 negative:

```text
people, human faces, silhouettes, crowds, text, letters, chalk writing, posters with text, watermark, logo, neon, oversaturated, daytime, windows with daylight, multiple lights, multiple lamps, lens flare, HDR, glossy, plastic, cgi render, cartoon, illustration, painting
```

Candidate 2 prompt:

```text
A single 35mm documentary photograph at night: a dark school hallway seen from the stairwell landing. One bare fluorescent tube over a closed classroom door is the only light source. Dust motes hang in its beam. Lockers and a blank noticeboard sit in deep blue-grey shadow. Desaturated, matte, heavy film grain, one small pool of cold gold light #f4c95d #8a755a on the floor, everything else #0b0c11 #14151c #282c30. No people, no writing.
```

Candidate 2 negative:

```text
people, faces, hands, silhouettes, text, writing, chalk marks, posters, watermark, logo, neon, oversaturation, daylight, windows, multiple lamps, emergency lights rows, lens flare, HDR, gloss, cgi, cartoon, illustration
```

#### 3.3.3 `hospital`: "clinical, never home"

Canon row (accent | sky and ambient | weather | rule): `#5dc8f4` **cyan** | `#0b0c11` / `#14151c` | clear | **warm chroma is specifically absent** — clinical, never "home".

- **Subject:** an empty ward corridor — the spine of `z_ward_corridor` — with a single abandoned gurney, one cold ceiling panel / exit light as the only source. No warmth anywhere: this is the district where warm chroma is specifically banned.
- **Composition:** long corridor receding to a windowless door in the far third; gurney off-center (left third) in the mid-ground; single light panel upper-center; pale curtain rail lines lead the eye; floor is polished dark tile with one long cold reflection.
- **Palette:** `#0b0c11` [A-sky], `#14151c` [A-sky], `#1d2629` [M], `#2c3534` [M], `#5dc8f4` [A], `#4a9ab5` [C-teal dim].
- **Mood:** The ward is a long cold held breath — a gurney that will not be wheeled, under the only light in a building that has given up being warm.

Candidate 1 prompt:

```text
A single 35mm documentary photograph, an empty abandoned hospital ward corridor at night. One-point perspective. A single abandoned gurney stands in the left third of the mid-ground. One cold fluorescent ceiling panel is the only light source, upper center. A windowless door sits in the far third. Pale curtain rails lead the eye. Polished dark tile floor with one long cold reflection. Muted, desaturated, matte, film grain. Colors: deep blue-grey #0b0c11 #14151c, cool greys #1d2629 #2c3534, one clinical cyan glow #5dc8f4 and its dim version #4a9ab5. No warm colors anywhere. No people.
```

Candidate 1 negative:

```text
people, faces, gurney wheels in motion, blood, gore, warm light, amber, orange, yellow, text, letters, signs with text, watermark, logo, neon, oversaturated, daytime, windows with daylight, multiple lights, lens flare, HDR, glossy skin, cgi, cartoon, illustration
```

Candidate 2 prompt:

```text
A single 35mm documentary photograph at night: a dark hospital corridor, an abandoned gurney with a thin sheet standing alone in deep shadow at center frame. One small exit-glow panel above a far door is the single light source. Fine mist sits in the beam. Desaturated matte documentary film, heavy grain. Cold teal-grey palette #0b0c11 #14151c #1d2629 #2c3534, one desaturated cyan pool of light #5dc8f4 on the tile floor. No warmth anywhere. No people.
```

Candidate 2 negative:

```text
people, faces, staff, warm light, amber, orange, sunset, text, writing, watermark, logo, neon, oversaturation, blood, daylight, windows, multiple lamps, lens flare, HDR, gloss, cgi, cartoon, illustration
```

#### 3.3.4 `gas_station`: "electric, not cozy"

Canon row (accent | sky and ambient | weather | rule): `#e85d3a` ember-orange | `#100d0a` / `#1a140f` brown-black | clear | canopy light must read **electric**, not cozy.

- **Subject:** the forecourt at night — `z_forecourt` / `z_pump_island`: the two pump rows under the canopy, the canopy flood as the single electric ember-orange source, wet concrete apron mirroring it. No cars in the foreground (one dead truck silhouette allowed in the deep background only).
- **Composition:** wide from across the apron; canopy line high in the frame; pumps in the mid-ground slightly left; the light pool dominates the lower half as a wet concrete mirror; kiosk silhouette in the right third; fog behind the canopy.
- **Palette:** `#100d0a` [A-sky], `#1a140f` [A-sky], `#26292c` [M], `#5c5245` [M], `#e85d3a` [A], `#8a755a` [M dim].
- **Mood:** The pumps are still counting fuel for a road nobody drives — the canopy hums electric ember-orange over a wet concrete mirror.

Candidate 1 prompt:

```text
A single 35mm documentary photograph at night: an abandoned gas station forecourt. Two rows of fuel pumps stand under a flat canopy in the mid-ground. The canopy floodlight is the single light source, casting an electric ember-orange pool on wet cracked concrete that mirrors it. A kiosk silhouette sits in the right third; one dead truck is barely visible in deep background fog. Muted, desaturated, matte, film grain. Cold and electric, not cozy. Colors: dark brown-black night #100d0a #1a140f, cool greys #26292c #5c5245, one ember-orange glow #e85d3a and its dim version #8a755a. No people.
```

Candidate 1 negative:

```text
people, faces, customers, drivers, lit shop windows, warm cozy light, amber, candlelight, readable signs, price digits, text, letters, watermark, logo, neon, oversaturated, daytime, blue sky, multiple floods, lens flare, HDR, glossy, cgi, cartoon, illustration
```

Candidate 2 prompt:

```text
A single 35mm documentary photograph at night, close on one abandoned fuel pump, its nozzle hanging. The canopy flood behind it is the only light source. Wet asphalt apron with oil-stain sheen and one long ember reflection. Dark brown-black night #100d0a #1a140f, cold grey mids #26292c #5c5245, one electric ember-orange glow #e85d3a. Fog behind. Desaturated, matte, documentary, heavy film grain. No people, no price digits.
```

Candidate 2 negative:

```text
people, faces, hands, cars in foreground, warm cozy light, amber, text, numbers, price signs, watermark, logo, neon, oversaturation, daytime, multiple lights, lens flare, HDR, gloss, cgi, cartoon, illustration
```

#### 3.3.5 `police`: "authority cold"

Canon row (accent | sky and ambient | weather | rule): `#5d5dc8` **indigo** | `#0a0a11` / `#12121c` | clear | authority-cold indigo ambient; sodium floods may read brass in-scene.

- **Subject:** the station's internal lamp court — `z_courtyard` — at night: the yard flood over an empty cobblestone court, the station's windowed facade in the background, one parked patrol-car silhouette (unlit, no people). Ambient is indigo-cold; the flood is the single warm brass note.
- **Composition:** low angle from the court edge; floodlight in the upper left third throwing one hard brass cone; facade with a single lit window in the right third; cobblestones and one wet reflection in the foreground; the patrol car silhouette mid-ground, side-on.
- **Palette:** `#0a0a11` [A-sky], `#12121c` [A-sky], `#282c30` [M], `#3c3e40` [M], `#c9a24a` [C-brass, the flood], `#5d5dc8` [A indigo ambient].
- **Mood:** The yard flood is still on for a shift that never ended — brass light on cobbles, indigo in every shadow, one window that watches back.

Candidate 1 prompt:

```text
A single 35mm documentary photograph at night, low angle across an empty cobblestone yard — the internal lamp court of an abandoned police station. One yard floodlight in the upper left third is the single light source, throwing a hard brass cone #c9a24a. The windowed station facade stands in the background with exactly one lit window in the right third. An unlit parked patrol car silhouette sits in the mid-ground, side-on. Indigo-cold ambient #0a0a11 #12121c #5d5dc8 fills every shadow; cool grey mids #282c30 #3c3e40. Wet cobbles carry one long reflection. Muted, desaturated, matte, film grain. No people.
```

Candidate 1 negative:

```text
people, faces, officers, crowds, lit windows more than one, siren lights, red and blue flashing, warm cozy light, text, letters, plates, badges with text, watermark, logo, neon, oversaturated, daytime, multiple floods, lens flare, HDR, glossy, cgi, cartoon, illustration
```

Candidate 2 prompt:

```text
A single 35mm documentary photograph at night: the entrance front of an abandoned police station. One sodium yard flood is the single light source over a wet barrier arm and a broken gate. The facade is in deep indigo-cold shadow #0a0a11 #12121c #5d5dc8; one small brass pool #c9a24a sits on wet concrete in the foreground. Fine mist in the beam. Cool grey mids #282c30 #3c3e40. Desaturated, matte, heavy film grain. No people.
```

Candidate 2 negative:

```text
people, faces, officers, siren lights, flashing red, flashing blue, warm cozy light, text, letters, emblems, watermark, logo, neon, oversaturation, daytime, multiple lights, lens flare, HDR, cgi, cartoon, illustration
```

#### 3.3.6 `warehouses`: "distant danger through fog"

Canon row (accent | sky and ambient | weather | rule): `#e85d3a` ember-orange | `#100d0a` / `#1a140f` | **fog** | first fogged district — accent reads distant through fog.

- **Subject:** the west shed's rack floor — `z_west_hall` — at night: aisles of pallet racking dissolving into fog, one high-bay flood as the single ember source, an unmanned forklift in the mid-ground, dust motes in the beam. (Canon: fog district — the accent must read *distant*, not close.)
- **Composition:** camera down an aisle between racks; vanishing point lost in fog in the upper-middle; forklift silhouette center-right in the mid-ground; high-bay light upper third; pallets and a belt fragment in the foreground corners.
- **Palette:** `#100d0a` [A-sky], `#1a140f` [A-sky], `#26292c` [M], `#3b3a38` [M], `#e85d3a` [A, dimmed by fog], `#8a755a` [M dim].
- **Mood:** The racks go on into fog that swallows the light before the light can swallow the dark — danger is not here, danger is just further down the aisle.

Candidate 1 prompt:

```text
A single 35mm documentary photograph at night: the interior of a vast abandoned warehouse rack floor. The camera looks down an aisle between tall pallet racking; the vanishing point is lost in heavy fog. One high-bay floodlight in the upper third is the single light source. An unmanned forklift silhouette stands center-right in the mid-ground. Dust motes hang in the beam. Pallets and a conveyor belt fragment sit in the foreground corners. Muted, desaturated, matte, film grain. Colors: dark brown-black #100d0a #1a140f, cool greys #26292c #3b3a38, one ember-orange glow #e85d3a softened by fog. No people.
```

Candidate 1 negative:

```text
people, faces, workers, forklift driver, warm cozy light, amber sunset, text, letters, pallet labels, watermark, logo, neon, oversaturated, daytime, windows with daylight, multiple floods, lens flare, HDR, glossy, cgi, cartoon, illustration
```

Candidate 2 prompt:

```text
A single 35mm documentary photograph at night: an abandoned loading yard between two warehouse sheds, open dock doors on both sides. One yard floodlight on a pole is the single light source. Thick ground fog. An unmanned forklift parked mid-yard is a dark silhouette. Wet concrete carries one long ember reflection. Dark brown-black #100d0a #1a140f, cool greys #26292c #3b3a38, one distant ember-orange light #e85d3a. Muted, desaturated, matte, heavy film grain. No people.
```

Candidate 2 negative:

```text
people, faces, drivers, cars, warm cozy light, text, letters, labels, signs, watermark, logo, neon, oversaturation, daytime, multiple lights, lens flare, HDR, cgi, cartoon, illustration
```

#### 3.3.7 `substation`: "the grid's nervous system"

Canon row (accent | sky and ambient | weather | rule): `#f4f45d` pale yellow-white | `#0c0c0c` / `#161616` | **fog** | coldest desaturated accent, near-bone; "the grid's nervous system".

- **Subject:** Yard C — `z_transformer_yard` — at night: rows of transformer tanks with bushings and insulator strings, overhead lines crossing the frame, one instrument/arc glow as the single near-bone white source, ground fog. The coldest frame of the seven: the accent is pale yellow-white `#f4f45d`, almost no chroma.
- **Composition:** low angle between two transformer banks, their tops in the upper third; insulator strings and cables drawing diagonals; the single arc glow low in the mid-ground between the banks; fog fills the lower half; fence silhouette on the horizon.
- **Palette:** `#0c0c0c` [A-sky], `#161616` [A-sky], `#282c30` [M], `#5a5956` [M], `#f4f45d` [A, desaturated], `#aeb6bf` [C-steel dim].
- **Mood:** Nobody lives in the grid — the yard hums with a light that has no home, bone-white and indifferent, swallowed by fog before it reaches the fence.

Candidate 1 prompt:

```text
A single 35mm documentary photograph at night, low angle between two rows of large electrical substation transformer tanks with porcelain insulator strings. Overhead power lines cross the upper third of the frame. One small instrument arc glow in the mid-ground is the single light source. Ground fog fills the lower half; a fence silhouette sits on the horizon. Muted, desaturated, matte, heavy film grain. Coldest possible frame: cold grey-black #0c0c0c #161616 #282c30 #5a5956, one desaturated pale yellow-white glow #f4f45d with almost no chroma, steel dim #aeb6bf. No people.
```

Candidate 1 negative:

```text
people, faces, workers, warm light, amber, orange, fire, lightning, electrical fire, sparks, text, letters, hazard markings, watermark, logo, neon, oversaturated, daytime, blue sky, multiple lights, lens flare, HDR, glossy, cgi, cartoon, illustration
```

Candidate 2 prompt:

```text
A single 35mm documentary photograph at night: a relay room corridor of an abandoned substation. Racks of sender relays stand in the foreground. One bare panel lamp is the single light source. A cable trench runs the floor. Fine dust hangs in the beam. Cold neutral grey-black #0c0c0c #161616 #282c30, one pale bone-white glow #f4f45d #aeb6bf, heavy ground fog at floor level. Desaturated, matte, film grain. No people.
```

Candidate 2 negative:

```text
people, faces, warm light, amber, orange, text, letters, readable dials, hazard signs, watermark, logo, neon, oversaturation, daytime, multiple lamps, lens flare, HDR, cgi, cartoon, illustration
```

### 3.4 Acceptance: the eight checks and the cluster targets

`python scripts/regen_cards_v2.py --raw-dir <raws> --out content/cards --emit-512 content/cards/twins --report report.json` exits 1 on any FAIL; no threshold is loosened per district. The checks (`docs/CARD_ART_BRIEF.md` section 6.1):

| Check | Threshold (measured against the 4 keeper cards) |
|---|---|
| Dimensions | exactly 1024×1536 |
| Texel range | min ≥ 16, max ≤ 240 (post-clamp, exact) |
| Saturation | median ≤ 28%; p99 ≤ 55%; share sat>40% ≤ 12% — **park**: median ≤ 35%, share sat>40% ≤ 30% (canon green-black base) |
| Hue family | ≥ 85% of pixels with sat ≥ 0.18 fall inside warm 25–52°, cool 180–235°, or district-accent ±14° — **park** additionally allows green 70–160° |
| Uniqueness | vs all 4 keeper cards: aHash (8×8) Hamming ≥ 8 AND 32×32 grey MAD ≥ 12 (in-cluster max is 6.2; nearest cross-cluster is 9/16.1) |
| Display band | center 230×84-aspect band luminance std ≥ 20 (legibility floor) |

Cluster targets (`python scripts/audit_card_clusters.py --images`): every card distinct from every other; aHash Hamming at least **8**, 32 x 32 grey MAD at least 12, k-means (k = 11) giving 11 singleton clusters.
The shipped set measures a minimum cross Hamming of **13** and a MAD from **20.5**; a new card that does not keep the floors is rejected, and the suburbs and residential keeper pair is the one named frozen exception.

## 4. Integration checklist for the final pass

1. **Licence rows first** (`docs/ASSET_LICENSES.md`), one per accepted file. 2. **Cards:** grade (3.4), then `python scripts/make_locked_cards.py` for the `_locked_512` variants, `python scripts/make_card_contact_sheet.py`, and the audit of 3.4;
   the twins replace `assets/textures/cards/card_<district>_512.png`. 3. **Music:** section 2.4, files at the exact paths; a track the game does not load yet needs the wiring named in `docs/MUSIC_SPEC.md` for its row, which is a code change
   with its own AF2 pair. 4. **Gates:** `bash tools/check.sh --static` (the audio and card gates, `gitignore_check`, `secret_scan`), `python tools/af5_check.py`. 5. **Frames:** a card shows in the collection screen only: re-shoot the
   frames of the collection view and read them (`docs/stills/`), or declare the reach in `tools/qa_sim/af3_f4_scope.tsv` if a runtime path changed. 6. **One launch:** `bash tools/check.sh --all`, then the 3-seed bot if a track was wired
   (`tools/qa_sim/autoplay_bot`). 7. **Bundle:** one export, then `python tools/qa_sim/aab_check.py build/tls.aab` (the bundle scan, `integrity` and `refs`), `version/code` raised.

## 5. Owner rows that are not for a generator (documented, not implemented)

| Row | State today | What the owner decides | What it touches |
|---|---|---|---|
| Crash reporting (Firebase, Crashlytics) | absent: `docs/PRIVACY_AUDIT.md` lists no analytics or crash SDK, and the bundle has no network call from a screen | whether the game reports crashes at all | the privacy policy and the data-safety answers change from "collects nothing" (`docs/STORE_SUBMISSION.md` sections 3 and 5), a Gradle plugin and a `google-services.json` (ignored by `.gitignore`), a consent screen where the law asks for one |
| Unlockable cosmetics | none exist: no cosmetic data, screen or save field; `docs/ACCEPTANCE_CHECKLIST.md` EC2 lists "skins" among things a shop may sell and `docs/GDD.md` section 8 was amended to a shop with no vendor | whether skins ship, how they unlock (play or coins) and that there is no purchase with money (the store answers say none) | art (binaries), `scripts/economy/shop_service.gd`, a save-field bump of `SAVE_VERSION` and its migration case (`docs/SAVE_MIGRATION_MATRIX.md`) |
| Survivor and Dark endings | a death resolves to Dark or Survivor (`EndingsManager.evaluate_death_ending`, GDD 12.4), the death screen keeps one picture (`assets/textures/screens_v2/death_loom.png`) and the five ending plates of `assets/store/endings/` ship in the bundle with no script that loads them | whether the death screen shows the earned plate, and whether Survivor and Dark are two endings or one | `scripts/ui/death_screen.gd`, `scripts/ui/win_screen.gd`, a frame re-shoot, the plates' place in the export filter (`docs/CORRECTION_LOG.md` 182) |
| Touch feel on a device | measured only on a desktop with the touch probe (23 of 23): the dead zone, the curve, the haptics and the calibration are the phone test's questions (U1, U5, U6, U13 of `docs/UNVERIFIABLE_HERE.md`) | the constants, after the numbers of a phone | `scripts/ui/virtual_joystick.gd`, `docs/RELEASE_RUNBOOK.md` section 4 |
| Remaining music | the 15 targets of 2.3 and the upgrade of the 11 beds of 2.2 | which of them are worth a take | section 2.4 and the licence ledger |
| Seven district card photographs | graded generated cards are in the game (3.1); the open points are the licence rows and a replacement if better art exists | replace or keep | section 3 and 4 |

