# Image asset prompt pack: LAST STREETLIGHT

Owner request, 2026-10-01: prompts for every picture in the game, and the game is renamed to
**Last Streetlight** (no "The"). Scope: 2D images only. 3D props and monsters live in
`ART_PROMPTS.md` (Meshy), audio in `ART_AUDIO_PROMPT.md`.

Canon this pack obeys: `PRODUCTION_BIBLE.md` §2 (palette, banned colours, fonts, chamfered UI),
`ART_UI_STYLE.md`, and the photographic house style from `CARD_ART_BRIEF.md` §4 that already produced
the seven district cards and the trailer stills. Numbers below were measured on disk on 2026-10-01
(924 PNG + 11 SVG) with a script, not copied from older reports.

## 0. The rename: what it touched, what it did not

An OCR pass over every PNG in the repo (RapidOCR, 924 files) found the old title baked into exactly
two shipped or marketing images and three dev captures. Everything else is textless, so no other
picture has to change because of the name.

| File | Size | Status |
|---|---|---|
| `store/feature-graphic.png` | 1024×500 | DONE. Same art; the old title was inpainted away and `LAST STREETLIGHT` set in the same font, size, colour, stroke and position. OCR of the new file reads it. |
| `store/trailer/presskit_1600x900.png` | 1600×900 | DONE, same method. Tagline and the three district captions untouched. |
| `assets/art/shot_game.png`, `shot_menu.png`, `shot_menu_3d.png` | 1920×1055 / 1280×720 | NOT touched. Unreferenced dev captures written by `scripts/tools/_shot.gd` and `_shot_3d.gd`, already flagged obsolete in `REPORT_ASSETS.md`. Re-capture after the next Godot run (lead), do not redraw. |

Not an image problem: `assets/textures/ui_v2/logo_grunge_512.png` is a textless stencil texture, the
in-game title is a font label, and the icons, capsules and key art carry no lettering.

Renamed in code and data (display name only):
- `data/i18n/en.json`: `menu_title`, `SHARE_TEXT`. The other 12 locale titles are translations of the
  idea ("DIE LETZTE LATERNE", "ПОСЛЕДНИЙ ФОНАРЬ", ...) and stay as they are.
- `scenes/ui/splash.tscn`, `menu.tscn`, `credits.tscn` default label text.
- `export_presets.cfg`: Windows `product_name` and `file_description`; the Android launcher label,
  which was the abbreviation `TLS`, is now `Last Streetlight`.
- Store copy (`store/*.md`, `docs/store/*.md`, privacy policy) and the titles of the living docs.
- Left alone on purpose: the Android package id `com.maxsimkasky.laststreetlight`, the internal
  prefix `TLS`, and history logs such as `RUN_STATE.md`.

**Not renamed on purpose: `project.godot` `config/name`.** Godot builds the `user://` folder from it
(`%APPDATA%\Godot\app_userdata\The Last Streetlight`), and `tools/qa_sim/user_data_guard.sh` reads the
same line. Changing it alone makes the game open an empty profile; the saves stay in the old folder.
Lead step, game closed, in this order (PowerShell):

```powershell
$ud = "$env:APPDATA\Godot\app_userdata"
Test-Path "$ud\The Last Streetlight.qa_snapshot"      # must print False; if True, launch the game once unguarded first
Move-Item "$ud\The Last Streetlight" "$ud\Last Streetlight"
# then set project.godot line 13 to config/name="Last Streetlight", launch once, check that Continue still finds the save
```

Rule for every new image: **never let an image model draw the title** (it misspells letters). Generate
text-free art; the wordmark is added afterwards (§10).

## 1. How to use

1. Pick a batch (§4). Batch A first: it defines the look of the whole game.
2. For each row, send the image model **STYLE block (§3) + the row's SUBJECT**, at the row's aspect
   ratio. Keep the best of 2-4 candidates.
3. Save the winner as a PNG named exactly like the row's `File` column into an `art_drop/` folder that
   is never committed. Then hand the folder to an agent with the prompt in §9.

Midjourney v7 and Flux.1-dev are the two engines the repo's earlier art used; the blocks work for both.

## 2. Tiers

| Tier | What | Count | Why |
|---|---|---|---|
| 1 | In-game hero art, §4 batches A-E | 73 generated + 7 crops | Today's in-game pictures are procedural placeholders (stick-figure monster portraits, blurred "photos", near-empty loading screens). Only the trailer stills and 7 district cards are real art. |
| 2 | Store masters, §5 | 0 to 4 | Eight text-free masters already exist in `store/trailer/`; crop them, generate only if you want a new look. |
| 3 | Icon sets, §6 | about 220 | Small and functional, already consistent and wired by exact name. Redraw only if you want a style upgrade. |
| - | Keep as they are, §7 | the rest | Tiles, UI chrome, LUTs, QA evidence, device mock-ups. |

Five groups are on disk but no script, scene or data file loads them yet (checked by grep over every
`.gd`, `.tscn`, `.tres`, `.json` and `.cfg` outside `docs/`): the district loading screens, the five
ending pictures (the ending screens load only audio), `docs_v2`, `stages_v2` and `journal_photo.png`. New art for them needs a wiring
pass by the owning agent (`menus` zone for screens, `world` for documents); the files themselves keep
their names.

## 3. Style blocks

Palette tokens (the only colours UI chrome may use; scenes should sit inside them too): bg-deep
`#0c1016`, panel `#141b24`, edge `#2a3340`, brass `#c9a24a`, brass-dim `#8a7338`, ember `#b4452f`,
steel `#aeb6bf`, bone `#d8d2c4`, stamina green `#5f8a4e`, teal `#4a9ab5`, fog `#1a2133`.
Banned: pure `#000000` and `#ffffff`, neon, saturated colours, a visible full moon, daytime.
Permanent night is the whole premise: cold dark ambient against warm point lights.

**Do not bake film grain or vignette into in-game pictures.** The engine adds both (8-12 % grain, edge
vignette) and baked grain makes a 1080p PNG 3-5× bigger. Grain is fine for store masters only.

### STYLE-PHOTO: scenes, districts, endings, backgrounds

Midjourney v7, append to the subject (add `--ar` from the row):
```
nocturnal documentary photograph, 35mm, one practical light source, heavy low fog, wet reflective ground, cold blue-black night #0c1016 #1a2133 with a single warm brass accent #c9a24a, muted desaturated colours, low-key exposure, generous negative space, clean and noise-free, no people --style raw --stylize 150 --no text, letters, watermark, logo, neon, daytime, blue hour, full moon, lens flare, HDR, glossy, plastic, cgi, cartoon, illustration, painting, extra light sources, vignette, film grain
```
Flux.1-dev, sentence form (subject first):
```
A single 35mm documentary photograph taken at night. <SUBJECT>. One practical light source only, heavy low fog, wet reflective ground. Cold blue-black night (#0c1016, #1a2133) with a single warm brass accent (#c9a24a). Muted desaturated colours, low-key exposure, generous negative space, clean and noise-free.
negative: people, faces, crowds, text, letters, watermark, logo, neon, oversaturated colours, daytime, blue hour sky, full moon, lens flare, HDR, glossy, plastic, cgi render, cartoon, illustration, painting, extra light sources, vignette, film grain
```
Rows that need the survivor in frame say so; for those drop `no people` / `people, faces` from the
negative and keep the figure small, seen from behind, face never visible.

### STYLE-CREATURE: monster plates, 2:3

Midjourney v7:
```
full-body dark horror creature photographed like a practical-effects film creature, centred, standing on a plain fog-black backdrop #0c1016, single brass rim light #c9a24a from camera left, matte desaturated skin, clean and noise-free, no gore, no blood --ar 2:3 --style raw --stylize 150 --no text, watermark, logo, scenery, cartoon, anime, neon, bright colours, glow
```
Flux.1-dev:
```
A full-body photograph of <SUBJECT>, shot like a practical-effects film creature. Centred on a plain fog-black backdrop (#0c1016), a single brass rim light (#c9a24a) from camera left. Matte desaturated skin, clean and noise-free, no gore, no blood.
negative: text, watermark, logo, scenery, props, cartoon, anime, neon, bright colours, glowing aura, gore, blood, multiple creatures
```

### STYLE-PROP: product-style renders (items, weapons, player)

```
studio product photograph of <SUBJECT>, worn and used, centred on a matte dark #141b24 surface, single warm brass key light #c9a24a from the left, faint cool rim light, shallow depth of field, desaturated, clean and noise-free --ar 1:1 --style raw --stylize 100 --no text, watermark, logo, hands, people, bright background, neon, glossy
```

### STYLE-PAPER: documents and journal pages

```
flat top-down scan of <SUBJECT>, aged cream paper in bone #d8d2c4 (never white), soft even light, faint stains and fold lines, illegible hand-drawn scribbles only, no readable letters or numbers --ar <AR> --style raw --no text, readable writing, watermark, logo, pure white, shadows from objects
```
Documents must contain **no readable text**: the game localises all copy in 13 languages and draws it
over the picture.

## 4. Tier 1: in-game hero art (73 generated images, 7 crops)

`File` is a path from the repo root. Replacing a file that already exists keeps its name and size, so
no code changes; rows marked NEW or "not wired" need the owning agent to hook them up. AR = aspect ratio
to request; export, then resize to the stated size without stretching.

### Batch A: the look of the game (11)

Folder `assets/textures/screens_v2/`, all 1920×1080, 16:9. STYLE-PHOTO, the survivor allowed small and
from behind. Menu layout guide (title label sits at 20 % height, the button column in the centre):
keep the central 36 % of the width dark and low-contrast, put the lamp and the figure in the right third.

| File | SUBJECT |
|---|---|
| `menu_hero.png` | A lone survivor seen from behind in a dark coat with a backpack and a hand-held flashlight, standing at the edge of the warm brass pool of the first working cast-iron streetlamp on a wet cobbled street; behind them a blacked-out city of concrete housing blocks dissolving into fog. |
| `menu_hero_dark.png` NEW | Same camera and framing as `menu_hero.png`, but the lamp is dead: the city is completely black and the survivor's flashlight beam is the only light. |
| `menu_hero_lit.png` NEW | Same camera and framing, the city restored: a long avenue of lit lamps receding into the distance, warm windows in the housing blocks, thinner fog, still night. |
| `menu_hero_generator.png` NEW | Same camera and framing, a diesel generator in a sandbagged yard with one work lamp on, thick cables snaking to a streetlamp that has just flickered on, the rest of the city dark. |
| `loading_street.png` | An empty wet street at night running to a vanishing point, one streetlamp lit far in the distance, nothing else lit, thick fog. No people. |
| `death_loom.png` | Looking up from the floor of a lightless room: a huge faceless dark silhouette bends over the camera, a dying flashlight rolls on the ground and throws a thin ember-red `#b4452f` glow across the floor. Shallow depth of field. |

The three NEW menu files are the `[M4]` "dynamic main menu, 3 backgrounds: day / night / generator on".
The game has no daytime (PRODUCTION_BIBLE pillar 1), so "day" is built as the restored-city state:
`dark` = night, `lit` = restored, `generator` = generator on. Generate `menu_hero_lit` first, then make
the other two from it with an image prompt or variation so the framing stays identical.

Folder `assets/store/endings/`, all 1920×1080, 16:9, STYLE-PHOTO, no people. Warmth runs coldest to
warmest in the order below (GDD §12.4, `ASSET_HANDOFF.md` W1), keep that order or the ending screens
stop reading correctly. Not wired to any ending screen yet.

| File | Condition | SUBJECT |
|---|---|---|
| `ending_dark.png` | death / grid not repaired | The whole city blacked out seen from a high rooftop in thick fog, no lights at all except one tiny ember-orange point very far away. The coldest frame in the game. |
| `ending_truth.png` | secret ending | An underground bunker corridor lit only by teal `#4a9ab5` emergency lights, one wall covered in pinned documents, photographs and cassette tapes joined by string, a heavy steel door standing open at the end. One empty chair. |
| `ending_survivor.png` | only District 11 | One single streetlamp lit in the middle of an otherwise dark ruined avenue, neutral white-brass light, a long empty shadow, nothing else lit anywhere. |
| `ending_hope.png` | all FULL, under 50 % documents | A city seen from a hill: a few districts glowing warm brass, many still dark, and on the far horizon a faint cold blue-grey dawn line. |
| `ending_light.png` | all FULL, all documents | The entire city seen from above glowing brass: every street a long grid of lit lamps, warm fog, the warmest frame in the game. |

### Batch B: districts (15)

Folder `assets/textures/loading/`, all 1280×720, 16:9, STYLE-PHOTO, **no people, one light source**.
Horizon in the upper third; keep the lower fifth low-detail (a progress bar and tip sit over it). Not wired yet.
Palettes per district are in `ART_AUDIO_PROMPT.md` (District-Specific Palette).

| File | SUBJECT |
|---|---|
| `suburbs_loading.png` | A quiet suburban street of small detached houses, hedges and low fences, one old cast-iron streetlamp far down the street as the single light, wet asphalt, mist. |
| `residential_loading.png` | A courtyard between Soviet-era concrete panel blocks, paper garlands still strung from balcony to balcony, a long table left from a street party under one sodium lamp on a pole, dark windows above. |
| `park_loading.png` | An abandoned park: a dead rusted carousel with peeling gold horses in a clearing, one old cast-iron park lantern as the only light, frozen pond edge and dead grass, bare tree limbs framing the top. |
| `school_loading.png` | A school locker corridor, a single flickering fluorescent tube as the only light, one open classroom door at the far end, linoleum reflecting it, scattered paper. |
| `hospital_loading.png` | An empty ward corridor, one abandoned gurney, a single cold ceiling panel or exit light as the only source. Cold teal-white only: no warm colour anywhere. |
| `gas_station_loading.png` | A petrol station forecourt, two rows of pumps under the canopy, the canopy flood as the single ember-orange source, wet concrete apron mirroring it, one dead truck silhouette far behind. |
| `police_loading.png` | A police station lamp court: one yard flood over an empty cobblestone court, the windowed facade behind, one unlit patrol car silhouette. Indigo-cold ambient, one warm brass flood. |
| `warehouses_loading.png` | The west shed of a warehouse: aisles of pallet racking dissolving into fog, one high-bay flood as the single ember source, an unmanned forklift mid-ground, dust motes in the beam. The light must read as distant. |
| `industrial_loading.png` | A foundry slag yard: tall smokestacks, a cold conveyor gantry, one furnace mouth glowing ember-orange as the single light, cinders and ground fog. |
| `substation_loading.png` | A transformer yard: rows of oil transformers with bushings and insulator strings, overhead lines crossing the frame, one instrument arc glow as the single near-bone-white source, ground fog. The coldest frame of the set. |
| `power_station_loading.png` | The power station from a service catwalk: huge cooling towers against fog, the turbine hall's one lit window as the single warm light, steam drifting. The last place in the city with a pulse. |

Folder `assets/textures/stages_v2/`, 256×144, 16:9, STYLE-PHOTO. One street, four stages: use the same
image prompt or seed so only the lighting changes. Not wired yet.

| File | SUBJECT |
|---|---|
| `stage_dark_256x144.png` | The suburban street with every lamp dead, only faint cold fog light. |
| `stage_partial_256x144.png` | The same street, two lamps lit and flickering, the rest dead. |
| `stage_streets_256x144.png` | The same street, every street lamp lit warm, the house windows still dark. |
| `stage_full_256x144.png` | The same street, every lamp lit and the house windows glowing warm, thinner fog. |

### Batch C: creatures (12 plates, 7 crops)

Folder `assets/textures/portraits_v2/`, all 512×768, 2:3, STYLE-CREATURE. Wired (encyclopedia and monster
data). `sharpshooter` is the roster id of the GDD's Sniper. The roster and its rules are
GDD §6.2; the old-five look comes from `ART_AUDIO_PROMPT.md` and `ART_PROMPTS.md`. Monsters are former
people (GDD §12.3): wrong proportions, no gore.

| File | SUBJECT |
|---|---|
| `shadow_full_512x768.png` | A gaunt humanoid silhouette 2.2 m tall, featureless matte pitch-black skin, arms hanging to the knees, thin tapered fingers, no face, slightly hunched; only a faint blue `#1a1a3e` rim separates it from the dark. |
| `crawler_full_512x768.png` | A quadruped crawling creature 1 m long, mottled brown chitinous skin, flat segmented body low to the ground, many small limbs under the body, a blind head with sensory whiskers, two tiny ember-red eyes. |
| `watcher_full_512x768.png` | A tall thin figure 2.4 m, pale grey-blue cracked flesh, no face except two pale glowing eyes, long spindly arms hanging, motionless statue-like pose, floating 30 cm above the ground. |
| `hunter_full_512x768.png` | An athletic gaunt predator 1.9 m in dark tactical gear, desiccated dark grey leathery skin, sunken faceted eyes with ember-red glints, a jaw split into two mandibles, forward-leaning stance, a small brass lamp on one shoulder. |
| `destroyer_full_512x768.png` | A massive hulking humanoid 2.2 m, rust-brown cracked flesh like cooled slag fused with exposed gears and cables, one oversized right fist, head sunk into the shoulders, no visible eyes. |
| `boss_full_512x768.png` | The Architect: a tall skeletal humanoid 3.5 m, fused asymmetrical limbs, a composite angular mineral head with many dim sockets, floating, a dark cloak trailing, circuit-like brass `#c9a24a` veins glowing across torso and arms. |
| `sharpshooter_full_512x768.png` | The Sniper: a gaunt long-limbed marksman 2 m, hooded, one elongated telescopic eye fused over the right socket with a faint red lens glint, kneeling on one knee with a long improvised rifle of pipe and wire, patient stillness. |
| `brute_full_512x768.png` | The Brute: a massive armoured hulk 2.4 m, welded scrap plates over bloated flesh, a tiny head, thick arms dragging a steel girder, matte so light does not catch it, faint heat cracks where the plates meet. |
| `burner_full_512x768.png` | The Burner: a scorched gaunt humanoid with a swollen throat sac, blackened split skin, ember-orange fluid dripping from the mouth, small flames licking the forearms, smoke trails, hunched. |
| `rotter_full_512x768.png` | The Rotter: a slow bloated giant 2 m, swollen sagging grey-green flesh, fungal growth, hanging sacs, tiny vestigial arms, a muted yellow-green poisonous drip. |
| `hound_full_512x768.png` | The infected dog: 0.9 m tall, emaciated, patchy hairless skin over visible ribs, an elongated jaw with too many teeth, clouded pale eyes with ember-red glints, mid-lunge stance. |
| `tvar_full_512x768.png` | The Tvar, a mini-boss: a hunched shapeless mass of fused limbs and torsos 3 m wide, many arms of different sizes, several half-formed faces, too many joints, pale flesh under a harsh white light. |

Derived squares: crop the head and torso of each plate to 512×512, no new generation.

| File in `assets/textures/enemies/` | Source plate |
|---|---|
| `architect_512.png` | `boss_full` |
| `sniper_512.png` | `sharpshooter_full` |
| `brute_512.png`, `burner_512.png`, `hound_512.png`, `rotter_512.png`, `tvar_512.png` | the same-name plate |

### Batch D: collectibles and story pictures (19)

Folder `assets/photos/`, all 256×256, 1:1, STYLE-PHOTO written as a found snapshot from inside the
world. Wired (photo album); the ids stay. `last_streetlight` is the game's central image, not a name to change.

| File | SUBJECT |
|---|---|
| `abandoned_street.png` | A residential street with the silhouettes of rusted parked cars, fog, one distant dead lamp. |
| `broken_lamp.png` | A snapped cast-iron streetlamp lying across wet asphalt, its glass head shattered. |
| `dark_alley.png` | A narrow alley between brick walls, dumpsters, pitch black at the far end. |
| `empty_hospital.png` | A ward corridor with one cold ceiling panel, an abandoned gurney. |
| `foggy_avenue.png` | A wide avenue swallowed by fog, the lamps only faint smudges. |
| `last_streetlight.png` | The single working streetlamp of a blacked-out street glowing warm brass. |
| `night_substation.png` | A transformer yard under one bone-white arc glow. |
| `old_park.png` | A dead carousel in fog, one lantern. |
| `ruined_school.png` | A locker corridor with one flickering fluorescent tube. |
| `warehouse_shadow.png` | Warehouse racking in fog with one large dark shape standing between the aisles. |

Folder `assets/textures/docs_v2/`, all 256×340, 3:4, STYLE-PAPER (`--ar 3:4`). Not wired yet.

| File | SUBJECT |
|---|---|
| `doc_blueprint_256x340.png` | an engineer's blueprint of a transformer, grid lines and callouts as illegible scribbles |
| `doc_circuit_256x340.png` | a hand-drawn wiring diagram with traced routes and small component symbols |
| `doc_letter_256x340.png` | a folded handwritten letter, lines of illegible script, a coffee ring |
| `doc_map_sketch_256x340.png` | a hand-sketched map of city blocks with a few red crosses |
| `doc_photo_monster_256x340.png` | a page with a small Polaroid clipped to it showing a dark tall silhouette |
| `doc_photo_street_256x340.png` | a page with a small Polaroid of a street with one lit lamp |

Folder `assets/textures/screens_v2/`, all 1920×1080, 16:9.

| File | SUBJECT |
|---|---|
| `journal_paper.png` | STYLE-PAPER: an aged cream notebook page filling the frame, faint ruled lines, a coffee ring, soft edge shadows, no text. Wired (journal). |
| `journal_photo.png` | STYLE-PHOTO: a Polaroid lying on a dark table, the picture inside showing a single lit lamp on a dark street, shallow depth of field. Not wired. |
| `character_dim.png` | STYLE-PHOTO: a blurred, mostly dark corner of a safehouse workbench, one warm lamp out of focus top-left, calm dark centre for UI panels. Wired (character screen). |

### Batch E: tutorial and renders (16)

Folder `assets/textures/onboard_v2/`, STYLE-PHOTO, text-free (the game draws the captions). Wired.

| File | Size / AR | SUBJECT |
|---|---|---|
| `onboard_01_spawn_256x144.png` | 256×144, 16:9 | A dark suburban street, a small survivor silhouette far from the camera, houses dark, one flashlight beam. |
| `onboard_02_light_256x144.png` | 256×144, 16:9 | A hand-held flashlight beam cutting a cone through fog on an empty street. |
| `onboard_03_streetlight_256x144.png` | 256×144, 16:9 | A dead cast-iron streetlamp with an open fuse box at its foot and a coil of cable on the ground. |
| `onboard_04_district_256x144.png` | 256×144, 16:9 | A small district seen from a rooftop: a few streets just lit warm, the rest dark. |
| `onboard_05_light_cone_1024x576.png` | 1024×576, 16:9 | A wide flashlight beam on a concrete wall in a dark corridor, dust in the beam, a small dark shape at the edge of the light. |
| `onboard_06_cable_box_1024x576.png` | 1024×576, 16:9 | A close view of an open street fuse box with cables and two brass-handled switches, pooled in flashlight. |
| `onboard_07_crouch_hunter_1024x576.png` | 1024×576, 16:9 | A crouching survivor behind a dumpster seen from behind; in the street beyond, a tall hunter silhouette with red-glinting eyes and one small shoulder lamp walks past. |

Folder `assets/textures/renders_v2/`, STYLE-PROP, 1:1 unless noted. Wired (weapon compare, character screen).

| File | Size | SUBJECT |
|---|---|---|
| `player_512x768.png` | 512×768, 2:3 | A survivor standing in three-quarter view, worn dark hooded coat, backpack, a hand-held flashlight, face in shadow (use STYLE-CREATURE framing). |
| `backpack_256.png` | 256×256 | a worn canvas backpack |
| `battery_pack_256.png` | 256×256 | a rugged battery pack with brass terminals |
| `medkit_256.png` | 256×256 | a dented first-aid kit with a faded red cross |
| `tools_256.png` | 256×256 | a bundle of hand tools: wrench, pliers, screwdriver |
| `bundle_survivor_256.png` | 256×256 | a survivor's bundle: backpack, rolled blanket, canned food, flashlight |
| `weapons/pistol_render_256.png` | 256×256 | a worn semi-automatic pistol, scratched dark steel frame, tape-wrapped grip, simple iron sights |
| `weapons/rifle_render_256.png` | 256×256 | a weathered bolt-action rifle, scratched dark metal, worn wooden stock, simple iron sights |
| `weapons/shotgun_render_256.png` | 256×256 | a double-barrel break-action shotgun, scratched dark barrels, worn wooden stock, a simple brass sight |

## 5. Tier 2: store and marketing art (crop, do not regenerate)

Eight text-free masters already exist, OCR-checked: six 16:9 (`store/trailer/hero_first_restore`,
`hero_grid_cascade`, `hero_reactor_room`, `still_first_light`, `still_first_ending`,
`still_grid_cascade`, each `_1920x1080.png`) and two 9:16 (`hero_shorts_cut_1080x1920.png`,
`shorts_silhouette_1080x1920.png`). The pictures under `assets/store/` are older procedural
placeholders (flat triangles of light); rebuild them from the masters with `cover()` from §10.
Generate a new master only if you want a different look: STYLE-PHOTO, 16:9, the survivor small and
from behind, the lamp and figure in one third, the other 40 % quiet for the wordmark (store masters
may keep a little grain).

| Target | Size | Master | Anchor `ax, ay` | Wordmark |
|---|---|---|---|---|
| `assets/store/background_1920x1080.png` | 1920×1080 | `hero_first_restore` | full frame | no |
| `assets/store/loading_screen_1920x1080.png` | 1920×1080 | `still_first_light` | full frame | no |
| `assets/store/main_menu_keyart_1920x1080.png` | 1920×1080 | `menu_hero.png` (Batch A) | full frame | no |
| `assets/store/library_hero_1920x620.png` | 1920×620 | `hero_first_restore` | 0.5, 0.55 | no |
| `assets/store/capsule_main_616x353.png` | 616×353 | `hero_first_restore` | 0.5, 0.5 | yes |
| `assets/store/capsule_header_460x215.png` | 460×215 | `still_first_light` | 0.5, 0.5 | yes |
| `assets/store/capsule_small_231x87.png` | 231×87 | `hero_first_restore` | 0.5, 0.35 | yes, title only |
| `assets/store/tv_banner_1280x720.png` | 1280×720 | `hero_grid_cascade` | full frame | yes |
| `assets/store/press/press_cover_1920x1080.png` | 1920×1080 | `still_first_ending` | full frame | yes |
| `assets/store/press/banner_discord_1280x640.png` | 1280×640 | `hero_first_restore` | 0.5, 0.5 | yes |
| `assets/store/press/banner_twitter_1500x500.png` | 1500×500 | `hero_grid_cascade` | 0.5, 0.5 | yes |
| `store/feature-graphic.png` | 1024×500 | DONE (§0) | | yes |

Everything under `assets/store/v2/` (about 100 files: social, itch, yandex, youtube, vertical, ab,
coming_soon, shots, storyboard) follows the same rule: **same file name, same size as the file that
is there now**, cut from the matching master (9:16 files from the two vertical masters). Do not redraw
them. Store screenshots must be real captures from the game; the 8 AI mock-ups in `store/screenshots/`
are for layout only. Device mock-ups in `assets/store/v2/devices/` are rebuilt from real captures.

Wordmark goes on the feature graphic, capsules, press cover and banners only. Never on the
background, library hero, loading art or key art: the store or the engine draws the logo there.

### Icon master

Two icon identities exist today: `store/icon-512.png` (a brass streetlamp lantern in a medallion, the
better one) and `assets/store/play_icon_512.png` (a silhouette under a cone), and the Android export
(`export_presets.cfg`, `launcher_icons/main_192x192`) ships the second. Pick one; this pack assumes
`store/icon-512.png` wins. To redo it: Midjourney v7,
```
app icon, a glowing brass Victorian streetlamp lantern inside a circular brass medallion frame on a dark navy rounded square, thin brass corner ornaments, warm light cone, a few small stars, centred, symmetrical, painted illustration, no text --ar 1:1 --style raw --no text, letters, watermark, photo, neon, white background
```
Derived files (no new generation):

| Target | Size | How |
|---|---|---|
| `assets/store/play_icon_512.png` | 512 | the master |
| `assets/store/icon_round_192.png` | 192 | circular mask |
| `assets/store/press/emblem_brass_512.png`, `store/press/icon_round_512.png` | 512 | circular mask |
| `store/icon-adaptive/foreground_1080x1080.png` | 1080 | the lamp alone on transparent, inside the central 66 % safe zone |
| `store/icon-adaptive/background_1080x1080.png` | 1080 | the navy field only, `#141b24` to `#0c1016` |
| `store/press/icon_mono_512.png` | 512 | the lamp as a flat white silhouette on transparent |

## 6. Tier 3: icon sets (optional, about 220 icons)

They are small, consistent, wired by exact file name and already readable, so redrawing them is a
style upgrade, not a fix. If you do it: generate each at 1024×1024, then downscale with Lanczos and check
it still reads at 64 px. Image models cannot output real alpha, so ask for a flat `#141b24` backdrop;
the integrator keys it to transparent and adds the 2 px brass ring (the `MaxFilter(5)` ring trick in
`.opencode/skills/asset_pipeline.md`). Do not draw the ring or a frame yourself.

Midjourney v7 template:
```
<SUBJECT>, single object icon, centred, front view, dark matte hand-painted look, soft top-left light, muted palette with steel #aeb6bf, bone #d8d2c4 and small ember #b4452f accents, plain flat #141b24 background, no text, no frame, no outline --ar 1:1 --style raw --no text, border, frame, drop shadow, neon, gradient background, photo background
```

| Set | Folder | Count / size | SUBJECT rule |
|---|---|---|---|
| Item icons | `assets/textures/items/<name>.png` | 56, 128×128 | the item named by the file |
| Achievement medals | `assets/textures/badges/badge_ach_01_128.png` to `_20_128.png` | 20, 128×128 | a circular brass medallion with the emblem below |
| District badges | `assets/textures/badges/badge_ach_district_<id>_128.png` | 11, 128×128 | a circular medallion with the district emblem |
| District crests | `assets/textures/crests/crest_<id>_96.png` | 11, 96×96 | the same district emblem as a single-colour brass heraldic crest |
| Skill icons | `assets/textures/icons/skills/<name>_96.png` | 15, 96×96 | a skill icon for the name in words (`crit_chance` = "critical hit chance") |
| Weapon icons | `assets/textures/icons/weapons/<w>_128.png`, `_holster_`, `_pressed_` | 9, 128×128 | the pistol, rifle or shotgun from §4 E; holster = the same weapon holstered; pressed = a slightly brighter variant |
| Status effects | `assets/textures/ui/status_{bleed,burn,poison,slow,stun}.png` | 5 | drop, flame, skull-in-cloud, snail-slow spiral, stars |
| Monster icons | `assets/textures/icons_v2/monster_{boss,crawler,destroyer,hunter,shadow,watcher}_64.png` | 6, 64×64 | a head-only emblem from the matching §4 C plate |

Item names (`assets/textures/items/`): alcohol, ammo, ancient_key, audio_log, backpack, backpack_l1,
backpack_l2, bandage, battery, blueprint, blueprint_backpack_capacity, blueprint_backpack_slots,
blueprint_flashlight_battery, blueprint_flashlight_brightness, bottle, cable, can_food, case, circuit, coin,
document, explosive, fabric, firework, flashlight, fuse, gas_canister, gear, gunpowder, icon_ammo,
icon_battery, icon_health, icon_stamina, key, lockpick, makeshift_lamp, medkit, metal, molotov, motor,
noise_bomb, paper, photo, pistol, radio_part, repair_kit, scope_lens, scrap, serum, taser, tool,
transformer, transistor, water, wiring, wrench. (`blueprint_*` = a rolled blueprint with a small symbol
of what it upgrades; `icon_*` are the HUD variants of the plain items.)

Achievement medal emblems (`ACH_01` to `ACH_20` in `en.json`): 01 First Light = one lit streetlamp; 02
Electrician = pliers and a bolt; 03 Beacon = a lamp with radiating rays; 04 Librarian = a stack of
documents; 05 Shadow Hunter = a beam hitting a shadow figure; 06 Quiet as a Mouse = a mouse; 07 Combo
Master = three chevrons; 08 Overloaded = a backpack bending under weights; 09 Photographer = a camera;
10 Seeker = a camera with a magnifier; 11 Economist = a coin stack; 12 Without a Scratch = an unbroken
shield; 13 The Architect = an angular crown with an eye; 14 Truth = an eye over a bunker door; 15
Darkness = a snuffed lamp; 16 Speedrunner = a stopwatch; 17 Collector = an album with a star; 18 Iron
Man = an iron helmet; 19 Midsummer Night's Dream = a bed under a moon; 20 Who's There? = a door ajar
with a shadow behind it.

District emblems: suburbs = a house; residential = a panel block; park = a bare tree; school = a
graduation cap; hospital = a cross; gas_station = a pump; police = a badge; warehouses = a crate on
a pallet; industrial = a gear and a stack; substation = a transformer; power_station = a cooling
tower with a bolt.

## 7. Keep as they are (do not regenerate)

- Tiling and technical textures: `assets/textures/tiles/` (44), `surfaces/` (27), `environment/`,
  `sky/`, `luts/`, `grading/`, `overlays_v2/`, `fx/`, `maps/` and `maps_v2/`. Image models cannot
  guarantee seamless tiles, exact grids or colour-grade ramps.
- UI chrome: `assets/textures/ui/` (buttons, bars, frames, crosshair), `ui_v2/` (panels, tabs, hex
  slots, weather cards, coin packs), `touch/`, `picto_v2/`, `icons_v2/branches`, `icons_v2/cycle`. The
  game draws chrome with `StyleBoxFlat` (chamfered, no gradients, no rounded corners by canon).
- The 11 district cards (`assets/textures/cards/`, `content/cards/`): unique art has existed for all
  11 districts since 2026-09-14.
- `assets/_orphaned/`, `assets/textures/items_legacy/`, `assets/store/play_final/`, `assets/store/storyboard/`
  (all excluded from the export), and every image under `docs/` (QA evidence).
- SVG icons in `assets/ui/*.svg`.

## 8. Delivery spec

- PNG, sRGB. Scenes and plates: RGB, no alpha. Icons and cut-outs: RGBA.
- Exact pixel size from the tables. Change the aspect ratio only by cover-cropping; never stretch.
- Budget: 512 px and under, about 500 KB or less; 1920×1080 scenes about 1.5 MB or less. Baked grain
  is the usual cause of an oversized PNG; if a file is still too big, reduce noise rather than
  quantising fog gradients.
- No readable text, logo or watermark in any picture. No pure `#000000` or `#ffffff` over 2 % of the
  pixels. Nothing neon, nothing daytime.
- File names are exact, including the mandatory `_512` suffix on enemy portraits.
- Replacing a file keeps its `.import` next to it. A new file gets its `.import` from the first
  Godot editor open; the lead commits those.
- Checks: `bash tools/check.sh --static` runs anywhere. Only a Godot run plus a person looking at the
  screen can judge art: `asset_check_scene.tscn` (needs the engine) and a windowed look through
  `tools/qa_sim/guarded_windowed`, by the lead.

## 9. Agent prompt: integrate delivered art

Paste into ZCode, OpenCode or Arena Agent after the images are in `art_drop/`. `assets/**` is in no
row of the `AGENT_ZONES.md` table, so this is a lead-run task: the lead merges and runs the engine.

```
You are the asset integrator for Last Streetlight (Godot 4.7). Read AGENTS.md first, then docs/ASSET_PROMPT_PACK.md.
Input: art_drop/ (never commit it). Each PNG is named exactly like the File column of a row in the pack.

For every file:
1. Find its row in the pack. No row: report it, do not guess a destination.
2. Resize to the row's size with Lanczos, cover-cropping only to fix the aspect ratio (anchor from the row, else centre). Never stretch.
3. Reject and report (do not place) a file that: contains readable text (run rapidocr-onnxruntime or tesseract, whichever installs), has more than 2 % pure #000000 or #ffffff pixels, is over its size budget after a lossless optimisation, or has the wrong aspect ratio by more than 3 %.
4. Scenes and plates: RGB. Icons: RGBA with the flat #141b24 backdrop keyed to transparent (soft threshold, 1 px feather) and the 2 px brass ring added as in .opencode/skills/asset_pipeline.md.
5. Derived files (the 7 enemy squares, the icon and store crops) are built by script from the placed masters; use cover() and add_wordmark() from section 10 where the pack says "wordmark yes".
6. Write to the target path. Keep the existing .import file. Never rename, move or delete a wired file.
7. Files marked "not wired" or NEW: place them, then list them for the owning agent (menus: screens and menu backgrounds, world: documents). Do not edit scripts or scenes yourself.

Then run: bash tools/check.sh --static, python tools/flow_check.py, python tools/scene_node_check.py. Commit one batch at a time ("Replace <batch> art"). Never push if you are a zone agent.

Report as a table: placed / rejected (reason) / derived, plus the files the lead must look at in the running game. Say plainly that none of it has been looked at in the engine. Do not claim an image is verified because it was resized.
```

## 10. Scripts used for the rename images (tested)

Both need `pip install pillow opencv-python`. Run from the repo root.

`cover()` and `add_wordmark()`: crop a master and set the canon wordmark (Bebas Neue, bone, soft
shadow; optional brass tagline in Roboto Condensed). Use for new art.

```python
from PIL import Image, ImageDraw, ImageFilter, ImageFont

BONE, BRASS = (216, 210, 196), (201, 162, 74)
TITLE = "LAST STREETLIGHT"


def cover(src, w, h, ax=0.5, ay=0.5):
    """Scale to fill w*h, then crop. ax/ay (0..1) pick which part of the picture survives."""
    im = Image.open(src).convert("RGB")
    s = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    x, y = round((im.width - w) * ax), round((im.height - h) * ay)
    return im.crop((x, y, x + w, y + h))


def _tracked(d, x, y, text, font, fill, track):
    for ch in text:
        d.text((x, y), ch, font=font, fill=fill)
        x += font.getlength(ch) + track
    return x


def _width(text, font, track):
    return sum(font.getlength(c) + track for c in text) - track


def add_wordmark(im, x=0.06, y=0.10, cap=0.12, tagline=None, align="left"):
    """Draw LAST STREETLIGHT (Bebas Neue, bone) and an optional brass tagline (Roboto Condensed)."""
    W, H = im.size
    size = round(H * cap / 0.70)                      # Bebas Neue cap height is about 0.70 em
    ft = ImageFont.truetype("assets/fonts/BebasNeue-Regular.ttf", size)
    fs = ImageFont.truetype("assets/fonts/RobotoCondensed-Regular.ttf", round(size * 0.30))
    tt, ts = size * 0.05, size * 0.30 * 0.14
    lines = [(TITLE, ft, BONE, tt, 0)]
    if tagline:
        lines.append((tagline.upper(), fs, BRASS, ts, size * 1.05))
    shadow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out = im.convert("RGBA")
    for layer, blur in ((shadow, size * 0.06), (None, 0)):
        d = ImageDraw.Draw(shadow if layer else out)
        for text, font, fill, track, dy in lines:
            w = _width(text, font, track)
            x0 = x * W if align == "left" else W / 2 - w / 2
            _tracked(d, x0, y * H + dy, text, font, (0, 0, 0, 170) if layer else fill, track)
        if layer:
            out.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    return out.convert("RGB")


# im = cover("store/trailer/still_first_light_1920x1080.png", 1024, 500, 0.5, 0.5)
# add_wordmark(im, x=0.05, y=0.62, cap=0.10, tagline="Restore the light. Every streetlight is life.").save("out.png")
```

`retitle()`: swap a title inside finished art whose text is solid colour on a dark picture. This is
exactly what produced the two rename images from the git originals (pixel-identical on re-run). It keeps
the original typeface, so use it for a title swap, not for new art.

```python
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"  # the font both original images used


def retitle(src, dst, region, old, new, align="left", stroke=0):
    """Erase the old title (solid-colour text on a dark picture) and set the new one in its place.
    region = (x0, y0, x1, y1) box around the old title only; stroke = outline width in px (0 = none)."""
    bgr = cv2.imread(src, cv2.IMREAD_COLOR)
    x0, y0, x1, y1 = region
    reg = bgr[y0:y1, x0:x1].astype(np.int32)
    lum = reg.sum(axis=2)
    fill = np.median(reg[lum >= np.percentile(lum, 98.5)], axis=0)      # text colour = brightest 1.5 %
    core = (np.abs(reg - fill).sum(axis=2) < 60).astype(np.uint8)       # glyph pixels
    ys, xs = np.nonzero(core)
    gx0, gx1, gy0, gy1 = xs.min() + x0, xs.max() + x0, ys.min() + y0, ys.max() + y0
    k = 2 * stroke + 3
    mask = np.zeros(bgr.shape[:2], np.uint8)
    mask[y0:y1, x0:x1] = cv2.dilate(core, np.ones((k, k), np.uint8))    # glyphs + outline + antialiasing
    clean = cv2.inpaint(bgr, mask, 5, cv2.INPAINT_TELEA)
    im = Image.fromarray(cv2.cvtColor(clean, cv2.COLOR_BGR2RGB))
    width = gx1 - gx0 + 1                                                # font size: old string must span the old width
    size = min(range(20, 160), key=lambda s: abs(ImageFont.truetype(FONT, s).getlength(old) - width))
    font = ImageFont.truetype(FONT, size)
    bb = font.getbbox(new)
    x = gx0 - bb[0] if align == "left" else round((gx0 + gx1) / 2 - (bb[2] - bb[0]) / 2) - bb[0]
    rgb = tuple(int(c) for c in fill[::-1])
    kw = {}
    if stroke:
        ring = cv2.dilate(core, np.ones((k, k), np.uint8)) - cv2.dilate(core, np.ones((k - 2, k - 2), np.uint8))
        kw = dict(stroke_width=stroke,
                  stroke_fill=tuple(int(c) for c in np.percentile(reg[ring.astype(bool)], 5, axis=0)[::-1]))
    ImageDraw.Draw(im).text((x, gy0 - bb[1]), new, font=font, fill=rgb, **kw)
    im.save(dst, optimize=True)


# retitle("store/feature-graphic.png", "out.png", (36, 44, 890, 112), "THE LAST STREETLIGHT", "LAST STREETLIGHT", "left", 2)
# retitle("store/trailer/presskit_1600x900.png", "out.png", (300, 55, 1300, 150), "THE LAST STREETLIGHT", "LAST STREETLIGHT", "center", 0)
```
