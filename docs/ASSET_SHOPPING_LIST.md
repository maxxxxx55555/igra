# Asset shopping list (owner buys or creates; music excluded, see OWNER_HANDOFF.md)

Status 2026-09-30 (rc14 beauty pass). The game runs on procedural geometry today, so nothing here blocks
a build: every row is an upgrade that replaces a placeholder. Canon for every purchase: `docs/STYLE_GUIDE.md`
(palette tokens, saturation under ~40% on surfaces, no pure black or white, cold darkness against brass
light) and `docs/PRODUCTION_BIBLE.md` section 4 (budgets below). Anything bought is re-tinted to the palette
in Godot; do not buy pre-lit or neon art.

**Licence criteria for every row (unless a row says otherwise):** CC0, or a commercial licence that allows
embedding in a distributed mobile app and redistribution inside the app package (Asset Store or Unity-only
EULAs that forbid use outside their engine do not qualify). CC-BY is acceptable only if the credits screen
can carry the attribution (one line per pack). No AI-training or "no derivative" clauses. Keep the licence
text next to the files (`assets/<pack>/LICENSE.txt`). Formats: `.glb`/`.gltf` for models, PNG for textures.

**Budgets (GDD 15, PRODUCTION_BIBLE 4):** under 50K polygons per district in view, under 200 draw calls (D1),
props at 512 px textures (about 500 KB each), hero textures at 2048 px, VRAM under 400 MB. Prefer one shared
atlas per pack. Measured now: 178 / 173 draw calls (D1 / D11), 1.34 M primitives per frame (over budget,
see PERF_PASS 18): a building kit must be low-poly modular, not detailed.

| # | Item | GDD cite | Pack type | Poly / texture budget | Today |
|---|---|---|---|---|---|
| 1 | Building kit: houses, panel blocks, clinic, school, police, warehouse, factory, substation, power station | 4.1 (11 districts), 11.1, STYLE_GUIDE 1 | Modular low-poly city kit (facade modules, roofs, doors, windows), e.g. Kenney City Kits (CC0) | 300-1500 tris per module, 1 atlas 1024 px per district family | `skyline.gd` dark boxes with lit window quads (visual only) |
| 2 | Street furniture: fences, barriers, dumpsters, bus stops, road signs, traffic lights, hydrants, bins | 4.1, 11 | Low-poly street props kit | 100-800 tris each, 512 px atlas | benches, cones, poles only (`street_props.gd`), 3 meshes in `assets/mesh` |
| 3 | Vehicles: wrecks, abandoned cars, one bus, one police car | 4.1 (police, gas_station, suburbs) | Low-poly car kit | 500-1500 tris each, 512 px | none |
| 4 | Vegetation: deciduous and dead trees, bushes, hedges, grass tufts | 4.1 (park, suburbs), 11 | Low-poly nature kit | tree 400-1200 tris, foliage cards allowed, 512 px | sphere on a cylinder |
| 5 | Ground and road materials: asphalt, cracked concrete, wet asphalt, gravel, grass, snow patches | 11.1, 11.6 | Seamless PBR or hand-painted tiles | 512 px seamless, 3 maps at most (albedo, normal, roughness) | 256 px tiles in `assets/textures/tiles` |
| 6 | Facade and wall decals: grime, cracks, peeling posters, graffiti (no readable brand names) | 11 | Decal / trim sheet pack | one 1024 px sheet | none |
| 7 | Monster models with skeleton and animation set (idle, walk, run, attack, hit, death): Shadow, Crawler, Watcher, Hunter, Destroyer, Sharpshooter, Brute, Burner, Rotter, Hound | 6.2 (roster), V.3 (enemy sheet) | Rigged creature / zombie characters, or a humanoid base plus creature add-ons | 2500-5000 tris, 1 texture 512-1024 px, 20-40 bones, shared humanoid rig preferred | one capsule body in `enemy_model.tscn` |
| 8 | Boss "The Architect" and mini-boss "Tvar" | 6.3, 6.2 | Custom or heavily modified creature; one hero character | boss 8-12K tris, 2048 px | primitive shapes in `boss_3d.gd` |
| 9 | First-person weapon models with hands: pistol, rifle, shotgun (draw, fire, reload animations) | 18 (weapons), 5 | FPS arms + weapon pack (Kenney Weapon Pack is CC0 for the guns) | 1500-4000 tris per weapon, 512-1024 px | `weapon_model.tscn` is a CSG box placeholder |
| 10 | Player body for the pause-menu and shadows (optional) | 2.1 | Low-poly humanoid | 3000 tris | 12 primitive meshes in `player_3d.tscn` |
| 11 | Pickup and interactable models: medkit, battery, coin, key, fuse box, cable box, workbench, generator, cabinet | 17, 20, 8 | Low-poly survival / industrial props | 200-800 tris, 512 px | tinted cubes |
| 12 | Hospital, school, police interior dressing (beds, desks, lockers, cells) if interiors are ever opened | 4.1 | Furniture / interior kit | 100-600 tris each | not needed for the current outdoor loop |
| 13 | VFX flipbooks: muzzle flash, fire drop (Burner), smoke, sparks, blood, dust motes | 6.4, 18 | Particle texture pack (soft, no saturated colours) | 256-512 px sheets | particle scenes in `scenes/vfx` with procedural meshes |
| 14 | Moon and cloud layer for the sky (optional) | 11.1 | Panorama or dome texture | 2048 x 1024 | `night_sky_panorama_2048x1024.png` (stars only) |
| 15 | Bebas Neue **Bold** (heading font) | 11.3 (V03) | Free, SIL OFL, from Google Fonts (owner download; the repo ships Bebas Neue Regular) | one `.ttf` | Regular only |
| 16 | Hand-drawn or photographic loading and menu keyart per district (optional polish) | 12 | Illustration commission | 1920 x 1080 | district loading images exist (`assets/textures/loading`) |
| 17 | Sound: monster voice and footstep sets for the 6 newer monster types, weapon foley beyond the delivered set, generator loop | 13, 22 | SFX library (CC0 or royalty-free) | each under 1 MB, total SFX under 50 MB | see the delivered-but-unwired table |
| 18 | Footstep recordings per speed (walk, jog, sprint) for the three surfaces that have one recording each: asphalt, puddle, glass | 13 (AU4), TZ_DECISIONS A03 | SFX library or a field recording (CC0 or royalty-free) | 9 files, each 0.2 to 0.5 s, wav 44.1 kHz | one recording per surface; speed is carried by volume and pitch |
| 19 | Radio voice lines for the three acts (a voice actor or a licensed voice pack) | 12.3 (SC8), TZ_DECISIONS SC8-radio | Voice recordings | about 20 short lines; every line would also need the 13 locales | none: the story reaches the player as documents, quests and the journal |

## Delivered but not wired (found by the rc14 two-grep sweep, no purchase needed)

| Files | State |
|---|---|
| `assets/audio/sfx/interact/*` (doors, cabinet, workbench, fuse, cable, generator, loot pickup, save, item drop), `ui_back.wav`, `shot_light.wav`, `shot_heavy.wav`, `monster_hunter_step.wav` | referenced by no script; needs an EventBus-driven table in `audio_manager.gd` (audio agent brief in RESUME_NOTE) |
| `assets/audio/sfx/weapons/*` (fire, reload, draw, holster, distant for pistol, rifle, shotgun) | belongs to the weapons row (GDD 18 / TZ G25) |
| `assets/audio/ambience/threat_low_loop.ogg`, `threat_high_loop.ogg`, `wav_src/*.wav` (about 30 MB) | constant low beds: do **not** wire (PRODUCTION_BIBLE 3, owner asked for no hum); quarantine candidates |
| `assets/_orphaned/**` (128 files), `assets/textures/badges`, `textures/cards`, `store/v2` | archive and store material; no in-game use is planned |
| `assets/env/*.tres` (night_environment_desktop/mobile, camera_attributes_night, mat_wet_asphalt, mat_foliage_sway, mat_lamp_flicker) | prepared materials with no load site anywhere (verified by grep); `mat_foliage_sway` and `mat_wet_asphalt` need real foliage and wet-road meshes (rows 4 and 5) before they can be wired, `mat_lamp_flicker` (wiring spec W4) could replace the batched lamp material without a purchase |

## Suggested purchase order

1. Rows 7 and 9 (monsters, first-person weapons): they change the moment-to-moment look the most.
2. Row 1 with row 5: turns the skyline placeholder into a street the player can read.
3. Rows 2 to 4 and 11: dressing.
4. Everything else as polish.
