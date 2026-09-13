# CARD ART BRIEF — 7 unique district photographs (producer-ready)

**Status: 7 districts specced, awaiting art.**

Owner: art pipeline. Date: 2026-09-13. Branch: `arena/card-art-pipeline`.
Feeds: `scripts/regen_cards_v2.py` (grade pipeline), `.pre-commit-config.yaml` (gate),
`docs/KNOWN_ISSUES.md` (defect record).

---

## 1. Why this brief exists

The collection screen (`scripts/ui/collection_ui.gd`) shows one card per district.
A measured visual audit (`docs/artifacts/visual-consistency/visual_consistency_report.md`,
`docs/KNOWN_ISSUES.md`) found that **all 11 districts are drawn from 4 base
photographs** — 7 districts show a photo that does not depict their own district.
The previous fix attempt (`arena/card-unique-rescue`) was rejected for shipping
zero card changes; a pre-commit gate now makes that impossible (see §8).

### Actual file layout (verified on disk, 2026-09-13)

| What | Where | Size |
|---|---|---|
| In-game card art (11 districts × unlocked + locked) | `assets/textures/cards/card_<district>_512.png` | 512×512 |
| Contact sheet (4 cols × 6 rows of 256 px thumbs — the 1024×1536 artifact) | `docs/artifacts/art-final/cards_contact_sheet.png` | 1024×1536 |
| The 4 base source photographs (trailer stills) | `store/trailer/hero_first_restore_1920x1080.png`, `hero_reactor_room_1920x1080.png`, `hero_grid_cascade_1920x1080.png`, `still_first_light_1920x1080.png` | 1920×1080 |
| **New graded masters (this pipeline's output)** | `content/cards/district_<district>.png` | **1024×1536** |
| On-screen display | 230×168 panel; art strip 230×84, `STRETCH_KEEP_ASPECT_COVERED` (center band of the card) | — |

> Note for the art team: the commission text referenced "4 existing good cards in
> `content/cards/district_*.png`". In this repo the 4 *unique base photographs*
> live in `store/trailer/` (full res) and `assets/textures/cards/` (graded 512²
> cards); `content/cards/` is the **new** home for the 7 graded 1024×1536 masters
> this brief specifies. All palette/composition numbers below were measured from
> the full-res trailer sources and the shipped 512² cards (Pillow 12 + numpy),
> not estimated.

## 2. Analysis of the 4 existing base photographs (measured)

### 2.1 The four photographs and their keeper districts

| Photo | Keeper district (depicts its own) | Borrows it (needs new art) |
|---|---|---|
| `hero_first_restore` — streetlamp, silhouetted figure waving, wet suburban street | **suburbs** | park, residential → park only (residential keeps `still_first_light`, see below) |
| `still_first_light` — ornate streetlamp, quiet **residential street** of single-family houses, one lit window | **residential** | school, hospital, gas_station, police |
| `hero_reactor_room` — glowing reactor tower in a vast machine hall, clocks, gantry silhouette | **industrial** | warehouses |
| `hero_grid_cascade` — aerial night city, diagonal light cascade sweeping the grid | **power_station** | substation |

Cluster evidence (aHash 8×8 Hamming + MAD on 32×32 greyscale, all 55 pairs):
intra-cluster Hamming 0–1 / MAD 1.06–6.2; nearest cross-cluster pair
(hospital/industrial) Hamming 9 / MAD 16.1. Four genuine clusters.

### 2.2 Measured palette per photograph (k-means k=6 on the full-res source; share = % of pixels)

| Photo | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| `hero_first_restore` | `#272a2a` 36% | `#181c1e` 30% | `#3c3c33` 18% | `#5d543f` 10% | `#8f7c55` 4% | `#ccbd8a` 2% |
| `hero_reactor_room` | `#26292c` 35% | `#161a1f` 28% | `#3b3a38` 17% | `#5c5245` 10% | `#8a755a` 7% | `#cdae7b` 2% |
| `hero_grid_cascade` | `#282c30` 36% | `#181c21` 28% | `#3c3e40` 18% | `#5a5956` 10% | `#877b6d` 6% | `#c1b198` 3% |
| `still_first_light` | `#131517` 34% | `#1d2629` 25% | `#2c3534` 20% | `#3d4642` 13% | `#69583b` 6% | `#aa8c5c` 2% |

Pattern in all four: **~60% cool near-black greys** (hue 190–215°, sat ≤ 30%) +
**~40% mid greys** + **≤ 8% warm brass-family** (hue 33–47°) concentrated in one
light source and its reflections. The warm share is always the *smallest*,
brightest cluster — the "cold darkness vs. warm light" rule of
`docs/STYLE_GUIDE.md` §1.

### 2.3 Measured composition (light centroid = mass-weighted centroid of the
brightest 0.5% of pixels, coordinates in 0–1 of frame)

| Photo | Light centroid | Composition |
|---|---|---|
| `hero_first_restore` | (0.54, 0.36) | Center-weighted; single lamp upper-center; reflective wet road fills lower third; houses mass right |
| `hero_reactor_room` | (0.57, 0.47) | Reactor mass right-of-center; diagonal gantry lower-left → center; one god-ray from upper left |
| `hero_grid_cascade` | (0.51, 0.41) | Diagonal cascade upper-right → lower-left; dark city mass in lower half |
| `still_first_light` | (0.35, 0.25) | Lamp upper-left; street recedes right; single lit window in right third |

Shared grammar: **one dominant practical light source, positioned in the upper
half**; a reflective or atmospheric foreground; deep negative space in at least
one third of the frame; subject readable in the **center horizontal band**
(the card is displayed as a 230×84 strip, `STRETCH_KEEP_ASPECT_COVERED`).

### 2.4 Measured tone, saturation, grain (full-res sources)

| Photo | lum p2/p50/p98 | median sat | p99 sat | % pixels sat>40% | grain (lap @480px) |
|---|---|---|---|---|---|
| `hero_first_restore` | 20/42/159 | 17% | 45% | 3.9% | 17.5 |
| `hero_reactor_room` | 17/42/147 | 21% | 47% | 4.4% | 27.4 |
| `hero_grid_cascade` | 19/45/160 | 19% | 40% | 0.9% | 26.3 |
| `still_first_light` | 18/38/115 | 30% | 54% | 10.9% | 15.2 |

Shipped 512² cards after grade: median sat 13–23%, texels clamped [16, 240],
vignette 0.6, film grain 0.04 (4%), 4 px district-accent border
(`docs/LEDGER_ARTFINAL.md` L4). `still_first_light` is the warmest keeper —
new photography must not exceed it.

### 2.5 The visual language (rules every new photo must obey)

1. **Muted/desaturated**: median saturation 15–25%; no surface saturation > 40%
   except the light source itself (`STYLE_GUIDE` §2 ban: sat > ~40% on surfaces).
2. **Nocturnal**: permanent night; darkest texel ≈ `#101418`, never pure black.
3. **Documentary photography**: 35 mm still, real materials, no HDR gloss, no
   stylized look.
4. **No visible people**: faceless featureless silhouettes only, and only if the
   spec calls for one. All 7 specs below call for **none** — keep the frames empty.
5. **Strong single light source**: exactly one warm (or spec-colored) practical
   light; everything else cold ambient from the district sky color.
6. **Hue families only**: cool blue-grey 190–225° + warm brass 33–47° + the
   district's own accent (±14°). No magenta, or neon leakage
   (`visual_consistency_report.md` §3, 0 outliers across 223 swatches today —
   keep it at 0). **Park exception**: park is the one canonically green-based
   district (sky `#0a110a`/`#12180f`, VISUAL_AUDIO_SPEC §1), so its
   green-black base (hue 70–160°) is allowed; for the other ten districts
   green is banned. The pipeline encodes both rules
   (`EXTRA_HUE_BANDS`, `sat_thresholds` in `regen_cards_v2.py`).
7. **No pure `#000000`/`#ffffff`**, no text, no watermark, no logos.
8. **Fog/atmosphere + wet reflective surfaces** in every frame (4/4 keepers).

## 3. District accents and sky bases (canon, `scripts/world/district_themes.gd`
via `docs/VISUAL_AUDIO_SPEC.md` §1)

| District | Accent | Sky/ambient | Weather | Rule |
|---|---|---|---|---|
| park | `#f4e35d` yellow-green | `#0a110a` / `#12180f` green-black | clear | only warm-green district — "the city's one living thing left" |
| school | `#f4c95d` gold | `#0b0c11` / `#14151c` blue-grey | clear | fluorescent-memory gold, institutional cold |
| hospital | `#5dc8f4` **cyan** | `#0b0c11` / `#14151c` | clear | **warm chroma is specifically absent** — clinical, never "home" |
| gas_station | `#e85d3a` ember-orange | `#100d0a` / `#1a140f` brown-black | clear | canopy light must read **electric**, not cozy |
| police | `#5d5dc8` **indigo** | `#0a0a11` / `#12121c` | clear | authority-cold indigo ambient; sodium floods may read brass in-scene |
| warehouses | `#e85d3a` ember-orange | `#100d0a` / `#1a140f` | **fog** | first fogged district — accent reads distant through fog |
| substation | `#f4f45d` pale yellow-white | `#0c0c0c` / `#161616` | **fog** | coldest desaturated accent, near-bone; "the grid's nervous system" |

Grading rule: **never introduce a warm chroma outside the district's own accent
color.** Hospital and police must not be brass-washed.

## 4. The 7 district specs

Common to all seven:

- **Deliverable**: 1 raw photograph per district, **1024×1536** (2:3 portrait),
  PNG, dropped into the art handoff; `scripts/regen_cards_v2.py` grades it and
  writes `content/cards/district_<district>.png`.
- **Camera**: street-level or human scale (one aerial allowed — none of the 7
  specs need it), 35 mm equivalent, slight depth of field OK, no tilt-shift.
- **Subject must fill the center horizontal band** (the on-screen 230×84 crop).
- **No people** in any of the seven frames (silhouettes allowed by the house
  rule but not requested here).
- **Negative space** in at least one third of the frame; **one light source**;
  fog or mist; wet/reflective ground where the surface allows.
- **Palette** below: [M] = measured from the keeper photo, [C] = canon token
  (`STYLE_GUIDE` §2), [A] = district accent.

---

### 4.1 `park` — "the city's one living thing left"

- **Currently borrows**: `hero_first_restore` (suburbs' streetlamp photo).
- **Subject**: the park's dead carousel at night — a rusted, canopy-lopped
  carousel standing in a clearing, frozen pond edge or dead grass in the
  foreground, one old park lantern as the only light. (Canon zones:
  `z_carousel`, `z_pond`, `z_grove_east`.)
- **Composition**: carousel centered on a slight off-axis (rule of thirds,
  right), lantern at mid-height in front of the carousel casting a short warm
  pool; bare tree limbs frame the top; fog flattens the background to flat
  green-black. No benches-with-people, no playground equipment in focus.
- **Palette**: `#0a110a` [A-sky], `#12180f` [A-sky], `#272a2a` [M],
  `#3c3c33` [M], `#f4e35d` [A], `#8f7c55` [M dim].
- **Mood**: The park is the only place in the city that was alive, and the
  carousel is still faintly, wrongly waiting to spin.

**Midjourney v7 (3 candidates — pick one):**

1. `nocturnal documentary photograph, 35mm, an abandoned city park at night: a dead rusted carousel with peeling gold horses in a clearing, one old cast-iron park lantern as the only light source casting a small warm pool, frozen pond edge and dead grass in foreground, bare winter tree limbs framing the top, heavy low fog flattening the background to flat green-black, muted desaturated film, palette #0a110a #12180f #272a2a #3c3c33 with a single pale yellow-green lantern glow #f4e35d, matte surfaces, no people, no text, no watermark, no neon, no pure black, no pure white --ar 2:3 --style raw --v 7`
2. `nocturnal documentary photograph, 35mm, low angle through bare tree trunks at a frozen park pond at night, a dead carousel barely visible in fog beyond the ice, one distant park streetlight on a wooden post as the single light source, wet dead grass and ice reflections in the foreground, deep green-black night #0a110a #12180f, desaturated muted film photography, faint yellow-green glow #f4e35d in one small pool of light only, matte, no people, no animals in focus, no text, no watermark --ar 2:3 --style raw --v 7`
3. `nocturnal documentary photograph, 35mm, an empty park chess pavilion at night beside a dead carousel, one bare-bulb pavilion lamp as the single light source over a dusty chess table, snow-dusted dead grass, tree grove dissolving into fog behind, cold green-black ambient #0a110a #12180f, muted desaturated 35mm film grain, one small warm-yellow-green light pool #f4e35d #8f7c55, everything else cold and dark, no people, no text, no watermark, no neon --ar 2:3 --style raw --v 7`

**Flux.1-dev (3 candidates — pick one):**

1. `A single 35mm documentary photograph taken at night in an abandoned city park. A dead rusted carousel with peeling gold horses stands in a clearing, slightly right of center. One old cast-iron park lantern is the only light source, casting a short warm pool on dead grass and the frozen edge of a small pond in the foreground. Bare winter tree limbs frame the top of the frame. Heavy low fog flattens everything behind into a flat green-black distance. Muted, desaturated, matte, film grain. Colors: deep green-black shadows #0a110a and #12180f, cool grey-brown mids #272a2a and #3c3c33, one small pale yellow-green lantern glow #f4e35d. No people. No text. No watermark. No neon. No pure black or pure white.`
   `negative: people, human faces, crowds, cars, headlights, moon visible in sky, full moon, text, letters, watermark, logo, neon, oversaturated colors, vivid green grass, lush plants, daytime, dusk, blue hour sky, lens flare, HDR, glossy, plastic, cgi render, cartoon, illustration, painting, extra light sources, multiple lamps`
2. `A single 35mm documentary photograph at night, low angle through the trunks of bare trees in a frozen park. Beyond the ice of a dead pond, a derelict carousel is barely visible through fog. One distant old park streetlight on a wooden post is the only light source, making a single small pool of pale yellow-green light #f4e35d on wet dead grass and ice. Deep green-black ambient #0a110a #12180f dominates the frame. Desaturated, matte, heavy film grain, one light source only.`
   `negative: people, faces, crowds, visible moon, stars, text, watermark, logo, neon, oversaturation, green grass, leaves on trees, daytime, blue hour, lens flare, HDR, glossy, cgi, cartoon, illustration, multiple lamps, streetlight rows, car lights`
3. `A single 35mm documentary photograph at night: an empty wooden park chess pavilion beside a dead carousel. One bare-bulb pavilion lamp is the single light source over a dusty chess table with scattered stones. Snow-dusted dead grass, a tree grove dissolving into fog behind. Cold green-black night #0a110a #12180f, cool grey mids #272a2a #3c3c33, one small warm pool #f4e35d #8f7c55. Muted desaturated film, matte surfaces, grain. No people.`
   `negative: people, faces, hands, crowds, text, letters, watermark, logo, neon, oversaturated, vibrant colors, daytime, dusk, full moon, lens flare, HDR, gloss, plastic, cgi render, cartoon, illustration, painting, extra lights, multiple lamps`

---

### 4.2 `school` — "institutional cold, fluorescent memory"

- **Currently borrows**: `still_first_light` (residential's street photo).
- **Subject**: the school's locker corridor at night — the long spine of
  `z_corridor_lockers` — a single flickering fluorescent tube as the only
  light, one open classroom door at the far end. (Canon: "every zone except
  the yard is interior, so the flashlight is the only light" — the card shows
  that interior cold.)
- **Composition**: one-point perspective down the corridor; lockers in the
  foreground sides, the open door dead-center in the far third; the flickering
  tube upper-third, center; chalk dust and fine mist in the light cone;
  linoleum floor carries the single reflection.
- **Palette**: `#0b0c11` [A-sky], `#14151c` [A-sky], `#282c30` [M],
  `#3c3e40` [M], `#f4c95d` [A], `#8a755a` [M dim].
- **Mood**: The school is holding its breath — one fluorescent tube still
  counting the children who are no longer here.

**Midjourney v7:**

1. `nocturnal documentary photograph, 35mm, interior of an abandoned soviet school corridor at night, one-point perspective down a long hallway, rusted metal lockers in the foreground sides, one open classroom door centered in the far third, a single flickering fluorescent tube as the only light source in the upper third, chalk dust and fine mist visible in its cone, wet linoleum floor with one soft reflection, cold blue-grey night palette #0b0c11 #14151c #282c30 #3c3e40 with one sickly gold fluorescent glow #f4c95d, muted desaturated film, matte, no people, no text, no watermark, no neon --ar 2:3 --style raw --v 7`
2. `nocturnal documentary photograph, 35mm, a dark school hallway at night seen from the stairwell landing, one bare fluorescent tube buzzing over a closed classroom door as the only light, dust motes hanging in its beam, lockers and a noticeboard in deep blue-grey shadow #0b0c11 #14151c #282c30, desaturated muted 35mm film, a single small pool of cold gold light #f4c95d on the floor, matte surfaces, heavy film grain, no people, no writing on walls, no text, no watermark --ar 2:3 --style raw --v 7`
3. `nocturnal documentary photograph, 35mm, an empty school gymnasium corridor junction at night, basketball court doors open to darkness, one emergency tube light above the doors as the single light source, fine chalk dust drifting in the beam, cold institutional blue-grey #0b0c11 #14151c #282c30 #3c3e40, one faint gold glow #f4c95d, desaturated matte documentary film, no people, no jerseys, no text, no watermark, no neon --ar 2:3 --style raw --v 7`

**Flux.1-dev:**

1. `A single 35mm documentary photograph, interior of an abandoned soviet school corridor at night. One-point perspective down a long hallway. Rusted metal lockers line the foreground sides. One open classroom door is centered in the far third. A single flickering fluorescent tube is the only light source, positioned in the upper third of the frame; chalk dust and fine mist are visible inside its cone. The wet linoleum floor carries one soft reflection. Muted, desaturated, matte, heavy film grain. Colors: cold blue-grey night #0b0c11 #14151c, cool greys #282c30 #3c3e40, one sickly gold fluorescent glow #f4c95d. No people.`
   `negative: people, human faces, silhouettes, crowds, text, letters, chalk writing, posters with text, watermark, logo, neon, oversaturated, daytime, windows with daylight, multiple lights, multiple lamps, lens flare, HDR, glossy, plastic, cgi render, cartoon, illustration, painting`
2. `A single 35mm documentary photograph at night: a dark school hallway seen from the stairwell landing. One bare fluorescent tube over a closed classroom door is the only light source. Dust motes hang in its beam. Lockers and a blank noticeboard sit in deep blue-grey shadow. Desaturated, matte, heavy film grain, one small pool of cold gold light #f4c95d #8a755a on the floor, everything else #0b0c11 #14151c #282c30. No people, no writing.`
   `negative: people, faces, hands, silhouettes, text, writing, chalk marks, posters, watermark, logo, neon, oversaturation, daylight, windows, multiple lamps, emergency lights rows, lens flare, HDR, gloss, cgi, cartoon, illustration`
3. `A single 35mm documentary photograph at night: an empty school corridor junction, gymnasium doors open to darkness, one emergency tube light above the doors is the single light source. Fine chalk dust drifts in the beam. Cold institutional blue-grey palette #0b0c11 #14151c #282c30 #3c3e40, one faint gold glow #f4c95d. Muted, matte, documentary, film grain. No people, no sports equipment in focus.`
   `negative: people, faces, silhouettes, text, letters, banners, watermark, logo, neon, oversaturated, daylight, multiple lights, bright gym, lens flare, HDR, glossy, cgi, cartoon, illustration, painting`

---

### 4.3 `hospital` — "clinical, never home"

- **Currently borrows**: `still_first_light` (residential's street photo).
- **Subject**: an empty ward corridor — the spine of `z_ward_corridor` — with a
  single abandoned gurney, one cold ceiling panel / exit light as the only
  source. No warmth anywhere: this is the district where warm chroma is
  specifically banned.
- **Composition**: long corridor receding to a windowless door in the far
  third; gurney off-center (left third) in the mid-ground; single light panel
  upper-center; pale curtain rail lines lead the eye; floor is polished dark
  tile with one long cold reflection.
- **Palette**: `#0b0c11` [A-sky], `#14151c` [A-sky], `#1d2629` [M],
  `#2c3534` [M], `#5dc8f4` [A], `#4a9ab5` [C-teal dim].
- **Mood**: The ward is a long cold held breath — a gurney that will not be
  wheeled, under the only light in a building that has given up being warm.

**Midjourney v7:**

1. `nocturnal documentary photograph, 35mm, an empty abandoned hospital ward corridor at night, one-point perspective, a single abandoned gurney in the left third of the mid-ground, one cold fluorescent ceiling panel as the only light source upper center, windowless door in the far third, pale curtain rails leading the eye, polished dark tile floor with one long cold reflection, palette #0b0c11 #14151c #1d2629 #2c3534 with a single clinical cyan glow #5dc8f4 #4a9ab5, absolutely no warm colors, muted desaturated film, matte, no people, no text, no watermark, no neon --ar 2:3 --style raw --v 7`
2. `nocturnal documentary photograph, 35mm, a dark hospital corridor at night, an abandoned gurney with a thin sheet standing alone center-frame in deep shadow, one small exit-glow panel above a far door as the single light source, fine mist in the beam, cold teal-grey night #0b0c11 #14151c #1d2629 #2c3534, one desaturated cyan pool of light #5dc8f4 on the tile floor, no warmth anywhere in the frame, matte desaturated documentary film, no people, no medical text, no watermark --ar 2:3 --style raw --v 7`
3. `nocturnal documentary photograph, 35mm, an abandoned hospital reception triage hall at night, long desk in foreground shadow, row of empty waiting chairs, one hanging tube light as the only source, dust in its cold beam, cold clinical cyan #5dc8f4 #4a9ab5 as the only chroma over deep blue-grey #0b0c11 #14151c #2c3534, desaturated matte 35mm film, heavy grain, no people, no signage text, no watermark, no neon --ar 2:3 --style raw --v 7`

**Flux.1-dev:**

1. `A single 35mm documentary photograph, an empty abandoned hospital ward corridor at night. One-point perspective. A single abandoned gurney stands in the left third of the mid-ground. One cold fluorescent ceiling panel is the only light source, upper center. A windowless door sits in the far third. Pale curtain rails lead the eye. Polished dark tile floor with one long cold reflection. Muted, desaturated, matte, film grain. Colors: deep blue-grey #0b0c11 #14151c, cool greys #1d2629 #2c3534, one clinical cyan glow #5dc8f4 and its dim version #4a9ab5. No warm colors anywhere. No people.`
   `negative: people, faces, gurney wheels in motion, blood, gore, warm light, amber, orange, yellow, text, letters, signs with text, watermark, logo, neon, oversaturated, daytime, windows with daylight, multiple lights, lens flare, HDR, glossy skin, cgi, cartoon, illustration`
2. `A single 35mm documentary photograph at night: a dark hospital corridor, an abandoned gurney with a thin sheet standing alone in deep shadow at center frame. One small exit-glow panel above a far door is the single light source. Fine mist sits in the beam. Desaturated matte documentary film, heavy grain. Cold teal-grey palette #0b0c11 #14151c #1d2629 #2c3534, one desaturated cyan pool of light #5dc8f4 on the tile floor. No warmth anywhere. No people.`
   `negative: people, faces, staff, warm light, amber, orange, sunset, text, writing, watermark, logo, neon, oversaturation, blood, daylight, windows, multiple lamps, lens flare, HDR, gloss, cgi, cartoon, illustration`
3. `A single 35mm documentary photograph at night: an abandoned hospital reception triage hall. A long desk sits in foreground shadow, a row of empty waiting chairs beside it. One hanging tube light is the only light source; dust drifts in its cold beam. Cold clinical cyan #5dc8f4 #4a9ab5 is the only chroma over deep blue-grey #0b0c11 #14151c #2c3534. Desaturated, matte, heavy film grain. No people, no signage text.`
   `negative: people, faces, staff, warm light, amber, orange, yellow, text, letters, posters, watermark, logo, neon, oversaturated, daylight, multiple lights, lens flare, HDR, cgi, cartoon, illustration, painting`

---

### 4.4 `gas_station` — "electric, not cozy"

- **Currently borrows**: `still_first_light` (residential's street photo).
- **Subject**: the forecourt at night — `z_forecourt` / `z_pump_island`: the
  two pump rows under the canopy, the canopy flood as the single electric
  ember-orange source, wet concrete apron mirroring it. No cars in the
  foreground (one dead truck silhouette allowed in the deep background only).
- **Composition**: wide from across the apron; canopy line high in the frame;
  pumps in the mid-ground slightly left; the light pool dominates the lower
  half as a wet concrete mirror; kiosk silhouette in the right third; fog
  behind the canopy.
- **Palette**: `#100d0a` [A-sky], `#1a140f` [A-sky], `#26292c` [M],
  `#5c5245` [M], `#e85d3a` [A], `#8a755a` [M dim].
- **Mood**: The pumps are still counting fuel for a road nobody drives — the
  canopy hums electric ember-orange over a wet concrete mirror.

**Midjourney v7:**

1. `nocturnal documentary photograph, 35mm, an abandoned gas station forecourt at night, two rows of fuel pumps under a flat canopy in the mid-ground, the canopy floodlight as the single light source casting an electric ember-orange pool on wet cracked concrete that mirrors it, kiosk silhouette in the right third, one dead truck barely visible in deep background fog, palette #100d0a #1a140f #26292c #5c5245 with a single ember-orange glow #e85d3a #8a755a, no cozy warmth, cold and electric, muted desaturated film, matte, no people, no readable signage, no text, no watermark, no neon --ar 2:3 --style raw --v 7`
2. `nocturnal documentary photograph, 35mm, close on a single abandoned fuel pump at night, nozzle hanging, the canopy flood behind it as the only light source, wet asphalt apron with oil-stain sheen and one long ember reflection, dark brown-black night #100d0a #1a140f, cold grey mids #26292c #5c5245, one electric ember-orange glow #e85d3a, fog behind, desaturated matte documentary 35mm film, no people, no price digits, no text, no watermark --ar 2:3 --style raw --v 7`
3. `nocturnal documentary photograph, 35mm, a gas station tanker apron at night, a lone rusted tanker silhouette in the far third, one yard floodlight as the single source raking across wet concrete, dust and fine mist in the beam, dark brown-black ambient #100d0a #1a140f, cool grey mids #26292c #5c5245, one hard ember-orange light #e85d3a, muted desaturated matte film, no people, no text, no watermark, no neon --ar 2:3 --style raw --v 7`

**Flux.1-dev:**

1. `A single 35mm documentary photograph at night: an abandoned gas station forecourt. Two rows of fuel pumps stand under a flat canopy in the mid-ground. The canopy floodlight is the single light source, casting an electric ember-orange pool on wet cracked concrete that mirrors it. A kiosk silhouette sits in the right third; one dead truck is barely visible in deep background fog. Muted, desaturated, matte, film grain. Cold and electric, not cozy. Colors: dark brown-black night #100d0a #1a140f, cool greys #26292c #5c5245, one ember-orange glow #e85d3a and its dim version #8a755a. No people.`
   `negative: people, faces, customers, drivers, lit shop windows, warm cozy light, amber, candlelight, readable signs, price digits, text, letters, watermark, logo, neon, oversaturated, daytime, blue sky, multiple floods, lens flare, HDR, glossy, cgi, cartoon, illustration`
2. `A single 35mm documentary photograph at night, close on one abandoned fuel pump, its nozzle hanging. The canopy flood behind it is the only light source. Wet asphalt apron with oil-stain sheen and one long ember reflection. Dark brown-black night #100d0a #1a140f, cold grey mids #26292c #5c5245, one electric ember-orange glow #e85d3a. Fog behind. Desaturated, matte, documentary, heavy film grain. No people, no price digits.`
   `negative: people, faces, hands, cars in foreground, warm cozy light, amber, text, numbers, price signs, watermark, logo, neon, oversaturation, daytime, multiple lights, lens flare, HDR, gloss, cgi, cartoon, illustration`
3. `A single 35mm documentary photograph at night: a gas station tanker apron. A lone rusted tanker silhouette stands in the far third. One yard floodlight is the single light source, raking across wet concrete; dust and fine mist sit in the beam. Dark brown-black ambient #100d0a #1a140f, cool grey mids #26292c #5c5245, one hard ember-orange light #e85d3a. Muted, desaturated, matte film. No people.`
   `negative: people, faces, warm cozy light, amber, fire, flames, explosions, text, numbers, watermark, logo, neon, oversaturated, daytime, multiple floods, lens flare, HDR, cgi, cartoon, illustration`

---

### 4.5 `police` — "authority cold"

- **Currently borrows**: `still_first_light` (residential's street photo).
- **Subject**: the station's internal lamp court — `z_courtyard` — at night:
  the yard flood over an empty cobblestone court, the station's windowed
  facade in the background, one parked patrol-car silhouette (unlit, no
  people). Ambient is indigo-cold; the flood is the single warm brass note.
- **Composition**: low angle from the court edge; floodlight in the upper
  left third throwing one hard brass cone; facade with a single lit window in
  the right third; cobblestones and one wet reflection in the foreground;
  the patrol car silhouette mid-ground, side-on.
- **Palette**: `#0a0a11` [A-sky], `#12121c` [A-sky], `#282c30` [M],
  `#3c3e40` [M], `#c9a24a` [C-brass, the flood], `#5d5dc8` [A indigo ambient].
- **Mood**: The yard flood is still on for a shift that never ended — brass
  light on cobbles, indigo in every shadow, one window that watches back.

**Midjourney v7:**

1. `nocturnal documentary photograph, 35mm, an abandoned police station internal lamp court at night, low angle across an empty cobblestone yard, one yard floodlight in the upper left third throwing a single hard brass cone #c9a24a, windowed station facade with exactly one lit window in the right third, an unlit parked patrol car silhouette in the mid-ground side-on, indigo-cold ambient #0a0a11 #12121c #5d5dc8 in every shadow, cool grey mids #282c30 #3c3e40, wet cobbles with one long reflection, muted desaturated documentary film, no people, no readable plates, no text, no watermark, no neon --ar 2:3 --style raw --v 7`
2. `nocturnal documentary photograph, 35mm, the entrance front of an abandoned police station at night, one sodium yard flood as the single light source over a wet barrier arm and broken gate, the facade in deep indigo-cold shadow #0a0a11 #12121c #5d5dc8, one small brass pool #c9a24a on wet concrete in the foreground, fine mist in the beam, cool grey mids #282c30 #3c3e40, desaturated matte 35mm film, heavy grain, no people, no stars above the sign, no text, no watermark --ar 2:3 --style raw --v 7`
3. `nocturnal documentary photograph, 35mm, an empty police station holding-court corridor mouth at night, cell bars in the foreground frame, one high window and a single bare tube as the only light source down the dark corridor, indigo-cold blue-black #0a0a11 #12121c #5d5dc8, one thin brass-grey beam #c9a24a #8a7338, dust in the air, desaturated matte documentary film, no people, no writing, no text, no watermark, no neon --ar 2:3 --style raw --v 7`

**Flux.1-dev:**

1. `A single 35mm documentary photograph at night, low angle across an empty cobblestone yard — the internal lamp court of an abandoned police station. One yard floodlight in the upper left third is the single light source, throwing a hard brass cone #c9a24a. The windowed station facade stands in the background with exactly one lit window in the right third. An unlit parked patrol car silhouette sits in the mid-ground, side-on. Indigo-cold ambient #0a0a11 #12121c #5d5dc8 fills every shadow; cool grey mids #282c30 #3c3e40. Wet cobbles carry one long reflection. Muted, desaturated, matte, film grain. No people.`
   `negative: people, faces, officers, crowds, lit windows more than one, siren lights, red and blue flashing, warm cozy light, text, letters, plates, badges with text, watermark, logo, neon, oversaturated, daytime, multiple floods, lens flare, HDR, glossy, cgi, cartoon, illustration`
2. `A single 35mm documentary photograph at night: the entrance front of an abandoned police station. One sodium yard flood is the single light source over a wet barrier arm and a broken gate. The facade is in deep indigo-cold shadow #0a0a11 #12121c #5d5dc8; one small brass pool #c9a24a sits on wet concrete in the foreground. Fine mist in the beam. Cool grey mids #282c30 #3c3e40. Desaturated, matte, heavy film grain. No people.`
   `negative: people, faces, officers, siren lights, flashing red, flashing blue, warm cozy light, text, letters, emblems, watermark, logo, neon, oversaturation, daytime, multiple lights, lens flare, HDR, cgi, cartoon, illustration`
3. `A single 35mm documentary photograph at night: the mouth of an abandoned police station holding-cell corridor. Cell bars frame the foreground. One high window and a single bare tube light are the only light source down the dark corridor. Indigo-cold blue-black #0a0a11 #12121c #5d5dc8, one thin brass-grey beam #c9a24a #8a7338, dust in the air. Desaturated, matte, documentary, film grain. No people, no writing on walls.`
   `negative: people, faces, hands, writing, text, letters, graffiti, siren lights, red blue flashing, warm light, amber, watermark, logo, neon, oversaturated, daytime, multiple lamps, lens flare, HDR, cgi, cartoon, illustration`

---

### 4.6 `warehouses` — "distant danger through fog"

- **Currently borrows**: `hero_reactor_room` (industrial's reactor hall).
- **Subject**: the west shed's rack floor — `z_west_hall` — at night: aisles
  of pallet racking dissolving into fog, one high-bay flood as the single
  ember source, an unmanned forklift in the mid-ground, dust motes in the
  beam. (Canon: fog district — the accent must read *distant*, not close.)
- **Composition**: camera down an aisle between racks; vanishing point lost
  in fog in the upper-middle; forklift silhouette center-right in the
  mid-ground; high-bay light upper third; pallets and a belt fragment in the
  foreground corners.
- **Palette**: `#100d0a` [A-sky], `#1a140f` [A-sky], `#26292c` [M],
  `#3b3a38` [M], `#e85d3a` [A, dimmed by fog], `#8a755a` [M dim].
- **Mood**: The racks go on into fog that swallows the light before the light
  can swallow the dark — danger is not here, danger is just further down the
  aisle.

**Midjourney v7:**

1. `nocturnal documentary photograph, 35mm, interior of a vast abandoned warehouse rack floor at night, camera down an aisle between tall pallet racking, the vanishing point lost in heavy fog, one high-bay floodlight as the single light source in the upper third, an unmanned forklift silhouette center-right in the mid-ground, dust motes hanging in the beam, pallets and a conveyor belt fragment in the foreground corners, dark brown-black ambient #100d0a #1a140f, cool grey mids #26292c #3b3a38, one ember-orange glow #e85d3a softened by fog, desaturated matte documentary film, no people, no text, no watermark, no neon --ar 2:3 --style raw --v 7`
2. `nocturnal documentary photograph, 35mm, an abandoned loading yard between two warehouse sheds at night, open dock doors on both sides, one yard floodlight on a pole as the single source, thick ground fog, an unmanned forklift parked mid-yard as a dark silhouette, wet concrete with one long ember reflection, dark brown-black #100d0a #1a140f, cool greys #26292c #3b3a38, one distant ember-orange light #e85d3a, muted desaturated 35mm film, no people, no readable pallet labels, no text, no watermark --ar 2:3 --style raw --v 7`
3. `nocturnal documentary photograph, 35mm, inside an abandoned cold-storage warehouse annex at night, frost on the walls, one hanging industrial lamp as the only light source, a single stacked pallet in the foreground, deep fog flattening the racks behind, cold grey-green-black #100d0a #1a140f #26292c, one small dim ember glow #e85d3a #8a755a, desaturated matte film, heavy grain, no people, no text, no watermark, no neon --ar 2:3 --style raw --v 7`

**Flux.1-dev:**

1. `A single 35mm documentary photograph at night: the interior of a vast abandoned warehouse rack floor. The camera looks down an aisle between tall pallet racking; the vanishing point is lost in heavy fog. One high-bay floodlight in the upper third is the single light source. An unmanned forklift silhouette stands center-right in the mid-ground. Dust motes hang in the beam. Pallets and a conveyor belt fragment sit in the foreground corners. Muted, desaturated, matte, film grain. Colors: dark brown-black #100d0a #1a140f, cool greys #26292c #3b3a38, one ember-orange glow #e85d3a softened by fog. No people.`
   `negative: people, faces, workers, forklift driver, warm cozy light, amber sunset, text, letters, pallet labels, watermark, logo, neon, oversaturated, daytime, windows with daylight, multiple floods, lens flare, HDR, glossy, cgi, cartoon, illustration`
2. `A single 35mm documentary photograph at night: an abandoned loading yard between two warehouse sheds, open dock doors on both sides. One yard floodlight on a pole is the single light source. Thick ground fog. An unmanned forklift parked mid-yard is a dark silhouette. Wet concrete carries one long ember reflection. Dark brown-black #100d0a #1a140f, cool greys #26292c #3b3a38, one distant ember-orange light #e85d3a. Muted, desaturated, matte, heavy film grain. No people.`
   `negative: people, faces, drivers, cars, warm cozy light, text, letters, labels, signs, watermark, logo, neon, oversaturation, daytime, multiple lights, lens flare, HDR, cgi, cartoon, illustration`
3. `A single 35mm documentary photograph at night: inside an abandoned cold-storage warehouse annex. Frost coats the walls. One hanging industrial lamp is the only light source. A single stacked pallet sits in the foreground. Deep fog flattens the racks behind. Cold grey-black #100d0a #1a140f #26292c, one small dim ember glow #e85d3a #8a755a. Desaturated, matte, heavy film grain. No people.`
   `negative: people, faces, warm cozy light, amber, fire, text, letters, labels, watermark, logo, neon, oversaturated, daytime, multiple lamps, lens flare, HDR, gloss, cgi, cartoon, illustration`

---

### 4.7 `substation` — "the grid's nervous system"

- **Currently borrows**: `hero_grid_cascade` (power_station's aerial cascade).
- **Subject**: Yard C — `z_transformer_yard` — at night: rows of transformer
  tanks with bushings and insulator strings, overhead lines crossing the
  frame, one instrument/arc glow as the single near-bone white source, ground
  fog. The coldest frame of the seven: the accent is pale yellow-white
  `#f4f45d`, almost no chroma.
- **Composition**: low angle between two transformer banks, their tops in the
  upper third; insulator strings and cables drawing diagonals; the single arc
  glow low in the mid-ground between the banks; fog fills the lower half;
  fence silhouette on the horizon.
- **Palette**: `#0c0c0c` [A-sky], `#161616` [A-sky], `#282c30` [M],
  `#5a5956` [M], `#f4f45d` [A, desaturated], `#aeb6bf` [C-steel dim].
- **Mood**: Nobody lives in the grid — the yard hums with a light that has no
  home, bone-white and indifferent, swallowed by fog before it reaches the
  fence.

**Midjourney v7:**

1. `nocturnal documentary photograph, 35mm, an abandoned electrical substation yard at night, low angle between two rows of large transformer tanks with porcelain insulator strings, overhead power lines crossing the upper third of the frame, one small instrument arc glow as the single light source low in the mid-ground, ground fog filling the lower half, fence silhouette on the horizon, cold grey-black night #0c0c0c #161616 #282c30 #5a5956, one desaturated pale yellow-white glow #f4f45d with almost no chroma, muted matte documentary film, no people, no readable markings, no text, no watermark, no neon --ar 2:3 --style raw --v 7`
2. `nocturnal documentary photograph, 35mm, a relay room corridor of an abandoned substation at night, racks of sender relays in the foreground, one bare panel lamp as the single light source, cable trench running the floor, fine dust in the beam, cold neutral grey-black #0c0c0c #161616 #282c30, one pale bone-white glow #f4f45d #aeb6bf, heavy ground fog at floor level, desaturated matte 35mm film, no people, no dial markings readable, no text, no watermark, no neon --ar 2:3 --style raw --v 7`
3. `nocturnal documentary photograph, 35mm, an arc cage at the edge of an abandoned substation at night, a fenced fault area in the mid-ground, one cage lamp as the single source, tensioned cables radiating from a pylon silhouette, deep fog, cold grey-black #0c0c0c #161616 #5a5956, one small pale yellow-white light #f4f45d, desaturated matte documentary film, heavy grain, no people, no text, no watermark, no neon --ar 2:3 --style raw --v 7`

**Flux.1-dev:**

1. `A single 35mm documentary photograph at night, low angle between two rows of large electrical substation transformer tanks with porcelain insulator strings. Overhead power lines cross the upper third of the frame. One small instrument arc glow in the mid-ground is the single light source. Ground fog fills the lower half; a fence silhouette sits on the horizon. Muted, desaturated, matte, heavy film grain. Coldest possible frame: cold grey-black #0c0c0c #161616 #282c30 #5a5956, one desaturated pale yellow-white glow #f4f45d with almost no chroma, steel dim #aeb6bf. No people.`
   `negative: people, faces, workers, warm light, amber, orange, fire, lightning, electrical fire, sparks, text, letters, hazard markings, watermark, logo, neon, oversaturated, daytime, blue sky, multiple lights, lens flare, HDR, glossy, cgi, cartoon, illustration`
2. `A single 35mm documentary photograph at night: a relay room corridor of an abandoned substation. Racks of sender relays stand in the foreground. One bare panel lamp is the single light source. A cable trench runs the floor. Fine dust hangs in the beam. Cold neutral grey-black #0c0c0c #161616 #282c30, one pale bone-white glow #f4f45d #aeb6bf, heavy ground fog at floor level. Desaturated, matte, film grain. No people.`
   `negative: people, faces, warm light, amber, orange, text, letters, readable dials, hazard signs, watermark, logo, neon, oversaturation, daytime, multiple lamps, lens flare, HDR, cgi, cartoon, illustration`
3. `A single 35mm documentary photograph at night: an arc cage at the edge of an abandoned substation. A fenced fault area stands in the mid-ground. One cage lamp is the single light source. Tensioned cables radiate from a pylon silhouette. Deep fog. Cold grey-black #0c0c0c #161616 #5a5956, one small pale yellow-white light #f4f45d. Desaturated, matte, documentary, heavy grain. No people.`
   `negative: people, faces, warm light, amber, fire, lightning, sparks, text, letters, signs, watermark, logo, neon, oversaturated, daytime, multiple lamps, lens flare, HDR, cgi, cartoon, illustration`

---

## 5. Generation notes

- **Midjourney v7**: submit all three candidates per district; keep the best.
  `--style raw` is mandatory (kills MJ's beauty pass); `--ar 2:3` is mandatory
  (1024×1536 master). If MJ returns 16:9, crop to 2:3 around the light source
  before grading.
- **Flux.1-dev**: guidance scale 3.5; 28–30 steps; 1024×1536 native if the
  sampler allows, else generate 1024×1536 via a 2:3-conditioned pipeline. Use
  the negative prompt verbatim. Two negatives to add if the model renders
  people: `human hands, feet, partial body`.
- **Rejection criteria on generation** (before it ever reaches the pipeline):
  visible people/faces, >1 light source, any green/magenta/neon chroma,
  readable text, watermark, pure black/white, daytime or blue hour, glossy/HDR
  look. Anything failing these is regenerated — do not grade it.
- **Licensing**: log every accepted generation (model, version, prompt id,
  seed where available, license tier) in `docs/ASSET_LICENSES.md` per project
  convention before commit.

## 6. Pipeline — `scripts/regen_cards_v2.py`

```
raw photo (1024×1536, artist handoff)
        │
        ▼
scripts/regen_cards_v2.py
  1. resize check (1024×1536 exact, --allow-other-dims to relax)
  2. histogram-matching color grade: per-channel CDF-matched LUT (256³) built
     from the district's reference keeper card (92% center region, border
     excluded) — this is the "color-grade LUT"
  3. clamp texels to [16, 240] (card family convention)
  4. deterministic film grain (seeded, default amplitude 0.04, --grain 0 to skip)
  5. validate (below) and write JSON report
        │
        ▼
content/cards/district_<district>.png   (graded 1024×1536 master)
        │  optional: --emit-512 <dir>
        ▼
<dir>/card_<district>_512.png  (center 512² crop + 4px district-accent border,
                                in-game format for assets/textures/cards/)
```

Usage (from repo root; needs `pillow` + `numpy`, e.g.
`python3 -m venv .venv && .venv/bin/pip install pillow numpy`):

```bash
# grade a single raw
.venv/bin/python scripts/regen_cards_v2.py --raw /handoff/district_park.png

# grade a batch
.venv/bin/python scripts/regen_cards_v2.py --raw-dir /handoff/raw/ --report /handoff/grade_report.json

# also emit the in-game 512² twins
.venv/bin/python scripts/regen_cards_v2.py --raw-dir /handoff/raw/ --emit-512 /tmp/cards512
```

Reference mapping (histogram target per district — overridable with
`--ref-card district=path`):

| District | Reference keeper card |
|---|---|
| park | `assets/textures/cards/card_suburbs_512.png` |
| school, hospital, gas_station, police | `assets/textures/cards/card_residential_512.png` |
| warehouses | `assets/textures/cards/card_industrial_512.png` |
| substation | `assets/textures/cards/card_power_station_512.png` |

Determinism: fixed seed (default 13), fixed k-means-free CDF matching, no
timestamps in output — identical inputs produce byte-identical PNGs.

### 6.1 Automatic validation (the script fails the build, exit 1, on any FAIL)

| Check | Threshold (measured against the 4 keeper cards) |
|---|---|
| Dimensions | exactly 1024×1536 |
| Texel range | min ≥ 16, max ≤ 240 (post-clamp, exact) |
| Saturation | median ≤ 28%; p99 ≤ 55%; share sat>40% ≤ 12% — **park**: median ≤ 35%, share sat>40% ≤ 30% (canon green-black base) |
| Hue family | ≥ 85% of pixels with sat ≥ 0.18 fall inside warm 25–52°, cool 180–235°, or district-accent ±14° — **park** additionally allows green 70–160° |
| Uniqueness | vs all 4 keeper cards: aHash (8×8) Hamming ≥ 8 AND 32×32 grey MAD ≥ 12 (in-cluster max is 6.2; nearest cross-cluster is 9/16.1) |
| Display band | center 230×84-aspect band luminance std ≥ 20 (legibility floor) |

Re-run after art lands: the card-cluster audit in
`docs/artifacts/visual-consistency/visual_consistency_report.md` §4 must then
show **11 distinct photographs** (cross-cluster Hamming ≥ 8).

## 7. The 4 keeper cards (untouched by this pipeline)

`suburbs`, `residential`, `industrial`, `power_station` keep their existing
photographs. Their locked twins and contact-sheet rows stay as-is. Do not
regenerate them — the histogram references in §6 point at them.

## 8. Gate — no more "zero card changes" PRs

`.pre-commit-config.yaml` installs `scripts/check_card_art_changes.py`:

- **Trigger**: the commit is made on a branch whose name contains `card`
  (e.g. `arena/card-art-pipeline`), or `CARD_ART_FORCE=1` is set, or the
  staged changes already touch `content/cards/` (trivially passing).
- **Rule**: when triggered, the commit must stage ≥ 1 file under
  `content/cards/`. On failure the hook prints
  `git diff --cached --stat -- content/cards/` (which will be empty) and
  rejects the commit.
- **CI/PR mode** (exact PR semantics from the commission): in GitHub Actions
  run `python3 scripts/check_card_art_changes.py --ci-base origin/<base>`; it
  then uses `git diff --stat <base>...HEAD -- content/cards/` and fails the
  check when it shows zero changes:

```yaml
# suggested .github/workflows/card-art-gate.yml (add when a PR workflow exists)
- name: Card-art PRs must change content/cards/
  run: python3 scripts/check_card_art_changes.py --ci-base "origin/${GITHUB_BASE_REF}"
```

- **Bypass**: `CARD_ART_BYPASS="<reason>"` (logged to stderr) or
  `git commit --no-verify` (the bootstrap commit that installs the gate
  itself is the one sanctioned use).

## 9. Definition of done

1. Seven accepted raw photographs (1024×1536), licensed per §5, one per
   district in §4.
2. `scripts/regen_cards_v2.py --raw-dir <raws> --report report.json` exits 0
   and writes seven files to `content/cards/` with a passing report.
3. `content/cards/` is included in the same PR/commit as the raw→graded
   files (the gate enforces this).
4. Re-run the card-cluster audit: 11/11 distinct, cross-cluster Hamming ≥ 8.
5. `docs/KNOWN_ISSUES.md` card entry closed; new 512² wiring to
   `assets/textures/cards/` is a **separate** code-touching PR (out of scope
   here — no GDScript/scene changes in this branch).
