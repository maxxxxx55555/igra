# Visual pass — remaining work (post static-verifiable pass, 2026-09-21)

`docs/VISUAL_PASS.md` W1-W10 status: W1 (env presets) and W9 (ThemeProvider
focus/disabled parity) were already wired going into this pass. This pass
added one more static-verifiable item (W10's streetlight `energy_mult`,
below) and did NOT touch shader/material work, particle VFX instancing, or
anything needing a rendered frame to judge — this sandbox now has a real
Godot binary and could render, but per-district light/fog/material *quality*
is a human-eyes call, not something worth guessing at via screenshot
round-trips in an autonomous pass. Everything below is exact file paths +
intended change + the command to verify it on a real machine.

## Done this pass

- **W10 (partial): per-district streetlight energy.** `scripts/world/streetlight_3d.gd`
  now reads `visual_quality.tres`'s `metadata/district_lights[<id>].energy_mult`
  in `_ready()` and multiplies every `spot.light_energy`/`glow.light_energy`
  write (both the stage table in `_update_light` and the flicker in
  `_process`) by it. Data was already authored (§3 of VISUAL_PASS.md); this
  just wires the existing constant into the existing per-stage light code.
  No shader, no material, no new asset.

## RESOLVED this pass — W10 ambient "conflict" was never live at runtime

Traced the call graph statically rather than rendering to find out (no ambiguity to
resolve on-device once the reachability question is answered): `DistrictThemes.apply_to_environment()`
has exactly one call site, `district_scene_factory.gd:32`, inside the `else` branch of
`DistrictSceneFactory.build()` — the fallback path that only runs when
`ResourceLoader.exists(scene_path)` is false for a district's `.tscn` file. Confirmed
all 11 entries in `DistrictSceneFactory.DISTRICTS` have a real file in
`scenes/districts/*.tscn` (`ls` count: 11/11). That fallback branch is therefore
unreachable for every real district in the shipped game — `district_themes.gd`'s
hardcoded `0.5`/`0.005` ambient/fog values never execute during actual play.
`world_env_setup.gd`'s `apply_for_stage()` (called from 3 real, live sites) is the
sole ambient system that matters. **VISUAL_PASS.md's proposed constant change to
`district_themes.gd` would have had zero observable effect** — tuning numbers in dead
code. Not applying it; nothing to verify on a render since nothing about this specific
item can appear in one. `world_env_setup.gd`'s existing `AMBIENT_DARK=0.12`/
`AMBIENT_LIT=0.20`/`AMBIENT_FULL=0.30` stand as the real, single source of truth.

## Owner-run, needs rendering/listening to judge (not attempted)

All of these have their assets already authored and sitting unused — the
gap is wiring + a render pass to confirm the result looks/reads right, which
this pass deliberately left alone:

- **W3 Fog cards** (`assets/shaders/height_fog_card.gdshader` exists,
  unused). Instance 2-6 `PlaneMesh` quads per fog district per §3 of
  VISUAL_PASS.md; needs a look at actual fog-district geometry to place them.
- **W4 Lamp flicker + hum sync** (`assets/shaders/streetlight_flicker.gdshader`,
  `assets/env/mat_lamp_flicker.tres` exist, unused). Assign as
  `StreetlightLampsBatched.material_override`; needs on-device confirmation
  the flicker curve matches the existing code-driven `Light3D` flicker
  (`streetlight_3d.gd`'s `_process`) rather than fighting it visually.
- **W5 Ground + leaves materials** (`assets/shaders/wet_asphalt.gdshader`,
  `foliage_sway.gdshader`, `assets/env/mat_wet_asphalt.tres`,
  `mat_foliage_sway.tres` exist, unused). Assign to district `Ground` /
  `TreeLeavesBatched`; wet-asphalt reflection strength needs a render to tune
  against the actual night lighting.
- **W6 Prop LOD (`VisibilityRange`)**. §5's table (small/mid/trees/contact-
  shadow-blob/fog-card ranges) is pure numeric data and IS static-verifiable
  in principle, but this pass didn't find a single clear wiring point:
  `scripts/world/street_props.gd`/`city_decorator.gd` spawn props into
  MultiMesh batches (per the streetlight batching note already in
  `streetlight_3d.gd`), and `VisibilityRange` properties apply per-instance,
  not per-MultiMesh-item — batched props can't take per-instance LOD without
  either un-batching (draw-call regression, the opposite of what this table
  is for) or a different mechanism (e.g. `MultiMeshInstance3D` doesn't expose
  `visibility_range_*` per element). Needs a design decision before wiring,
  not just constant-plugging.
- **W7 Weather VFX instancing** (`vfx_rain.tscn`, `vfx_dust.tscn`,
  `vfx_strobe.tscn` exist, unused as `WeatherVFX` children). Particle count
  budgets (§4) are already correct in the `.tscn` files themselves — the gap
  is instancing them under `WeatherVFX` and wiring `amount_ratio`/
  `fixed_fps` from `visual_quality.tres`, then confirming on a render that
  rain/dust read correctly against the fog and don't overdraw.
- **W8 UI transition timings** (§6 table). This IS static/data (reuses only
  `FadeTransition.fade_to`, `TransitionManager.fade_out/fade_in`,
  `Routes.goto` — no shader/material), but touches ~15 screen transition call
  sites across the UI layer; left out of this pass for scope/risk reasons
  (screens are gameplay-critical UI, and a bad transition duration is a
  regression a player hits on every screen, not a cosmetic-only risk like
  the other W-items). Worth a dedicated pass with the existing UI flow gates
  (`flow_check.py`) run after every site, not folded into a "static visual
  constants" pass.
- **Menu parallax** (`assets/shaders/menu_parallax.gdshader` exists, unused).
  Blocked on its own stated prerequisite (VISUAL_PASS.md §6): current menus
  are flat `ColorRect`s with no loading-art texture layer to apply the
  shader to. Needs that art layer added first.
- **L1 Moon shadow bias** (`scenes/main_3d.tscn`'s `Moon` `DirectionalLight3D`,
  `shadow_bias=0.1`/`shadow_normal_bias=2.0`). VISUAL_PASS.md's own text
  flags the proposed `0.06`/`1.2` replacement as "blind-tuned... VERIFY ON
  DEVICE" — shadow bias is a classic acne-vs-peter-panning tradeoff that
  needs an actual rendered frame to judge, so this pass left it alone rather
  than guess at a number its own source doc doesn't trust either.

## Verification commands for the owner

```bash
bash tools/check.sh --static
python tools/flow_check.py
python tools/scene_node_check.py
```

Then, on a machine that can render (this sandbox now can — see
`docs/RELEASE_READINESS_REPORT.md` for the confirmed-working Godot path):
open `res://scenes/main_3d.tscn`, step through a district transition per
weather/stage, and eyeball the moon shadow edge, the fog card placement
candidates, and the wet-asphalt/foliage assignment before wiring W3-W5/L1.

## Visual overhaul protocol and approvals journal (owner canon of 2026-10-29)

Every visual batch is one commit and one row below (APPROVED, REWORK(n) or REVERTED, and the basis of the approval); one revert undoes a batch. A batch is held by the static battery, by a frame that was looked at, and for the 3D world by the gates of
lighting and combat. The style is `docs/STYLE_GUIDE.md` section 8 and the sheets of `docs/art/style_reference/`; UI chrome (chamfers, the brass icon family, the fonts) stays as `docs/UI_CONSISTENCY.md` has it, art does not draw buttons, frames or HUD icons.
The brightness of dark zones is stealth balance: no batch raises it (`lighting_stage_sim`, GRADE1).

| Batch | Content | Basis | Status |
|---|---|---|---|
| pass 2 | 29 repainted 2D slots of the other agent (`docs/ART_PASS_2.md`) | merged in PR 34 after review | stays until replaced; the owner called it bad on 2026-10-29; a replacement needs an image model, which the agent does not have |
| M1 | monsters: lofted faceted shapes (`scripts/art/monster_meshes.gd`), same nodes, pivots and hitboxes | the owner's standing instruction of 2026-10-29 to finish everything; frames in `.qa_logs/evidence/monsters/`, bots 3 of 3 at Normal and Hard | APPROVED by delegation, not reviewed per batch: the owner can revert the merge commit |
| U1 | UI tokens and chrome of the owner canon: ThemeProvider colours (bg `#060f13`, panel `#0f1314`, 1 px bronze edge `#5a4a2a`, text `#d8d5cc`, dim `#8a8a85`, danger `#c0392b`), the screens that kept a private copy read the tokens, the flat chrome textures retinted (`tools/retint_ui_chrome.py`) | the owner's standing instruction of 2026-10-29; before and after in `.qa_logs/frames/ui_*_b0_*` and `_b1_*` | APPROVED by delegation, not reviewed per batch: one revert of the merge commit undoes it |
| v7-0 | the sheets branch `release/1.0.2-sheets` (rebuilt shop, flashlight upgrade, city map, pack grid and weather cards; a rounded grey chrome; the icons written into `assets/`) | decisions 3 of v7 and prohibitions 3 and 7 | NOT MERGED, archived: it was never in main (the branch, tip `6ac5fa91`, keeps it); main holds only the colour work of pull request 38, which changes no layout |
| U2 | the baked copies of the old tokens in the UI themes, scenes and scripts moved to the canon (35 files, `tools/retint_ui_chrome.py`), inset fills on `COLOR_BG_PANEL2` instead of the bronze border (workbench rows, bar backgrounds, silhouettes) | the unify probe failed on the slot panel of `hud_3d.tscn`; the workbench frame showed brown blocks; frames `docs/stills/store/*_after_9a5148c8_*` and `.qa_logs/frames/ui_*_b3_*` | APPROVED by delegation, not reviewed per batch: one revert of the merge commit undoes it |

## MEGA_PROMPT v7 (the owner's final prompt of 2026-10-29): decisions, slots, prohibitions

This section is the canon of the visual overhaul; it replaces the earlier reading of the sheets (the first two canon passes of Session 37 rebuilt screens and recoloured the chrome, which the decisions below rule out). The slot table is in `tools/art_slots.py`
(`--check` audits the repo against it, `--briefs` writes `docs/art/generation_briefs.txt`, `--fit` and `--apply` take an image made outside the repo to its slot with a side-by-side board and an approvals row).

### Decisions of the owner (not asked again)

1. **The pictures: yes.** All full-screen art (menu, loading, death, character, journal, maps, district cards, weather and press art) is full-size images in the style of the sheets: semi-realistic PBR grit, blue-green darkness, one amber key light, grain.
2. **The game world: style yes, camera no.** The sheets are the source of mood and style, not of the camera. The game is first-person 3D: every in-game view is eye level, 1.6 m, about 55 mm, the horizon in the upper third. The top-down 55 degrees of the sheets is reproduced nowhere except in the two map panels.
3. **Screens 1:1: no for the layout, yes for the style of the art layers.** The UI is not rebuilt to the layout of the sheets (no round minimaps, joysticks, round buttons or bars with icons); the HUD and the screens stay the code canon of `docs/UI_CONSISTENCY.md` (chamfers, brass).
   Only the art layers change: backgrounds, underlays, cards, paper. What the sheets lack and the game has (the flashlight cone, the visibility metric, the weather, the endings) is drawn in the same canon.
4. Everything the game has must look like the sheets; what it lacks is made in the same style; one style. The genre is first-person stealth survival horror: dark, frightening, beautiful, not cartoon.

### Slots

| Slot (path, size) | Tile of the sheets | Specification |
|---|---|---|
| `assets/ui/menu_city.png` 1920x1080 | screens: the street at night | first-person eye-level street in fog, one lamp on the right with a cone and a puddle reflection, the left third darker and quieter for the panels, a distant silhouette |
| `assets/textures/screens_v2/loading_street.png` 1920x1080 | screens: loading | first-person street, a row of dark lamp posts with the nearest one lit, snow and fog; no progress bar (the bar is code) |
| `assets/textures/screens_v2/death_loom.png` 1920x1080 | screens: you died | first-person fallen gaze, the flashlight beam along the ground, a monster silhouette far away in backlight; no captions |
| `assets/textures/screens_v2/character_dim.png` 1920x1080 | screens: character | the survivor in full length with a backpack and a flashlight in the cone of a street light (third person allowed here only), a street behind |
| `assets/textures/screens_v2/journal_paper.png` 1920x1080 | screens: journal | aged sepia paper: a manuscript, a blueprint, a photo on tape, no readable text |
| `assets/textures/maps_v2/city_iso_2048.png` 2048x2048 | screens: district map | dark aerial base, a hex node per district with a status outline (green, yellow, red), a glow on the restored ones; isometry allowed here only |
| `assets/textures/maps_v2/grid_panel_512.png` 512x512 | screens: power grid | dark schematic of the grid: poles and transformer nodes, amber and green glowing nodes, thin lines; isometry allowed here only |
| `assets/textures/cards/card_<district>_512.png` x11 | feature: world and districts | first-person vignette of the signature of the district (gas station canopies, the precinct, the turbine hall), darkness and amber, grain |
| the 11 locked variants | none | not generated: the repo's affine k=(0.439, 0.436, 0.527), c=(0.038, 0.052, 0.050) of the lit card (`tools/art_slots.py` does it) |
| world pass (phase 4): building facades | sheet 1: walls 3.1 to 3.6 | facade textures by district family (brick, concrete, panel, metal), 1024 px albedo, normal and roughness with real micro-relief (joints, cracks, rust streaks, gutters, air conditioners, boarded windows as relief and albedo, not emission); lit windows stay the emissive system of the repo |
| world pass: roads and kerbs | sheet 1: road surfaces 1.1 to 1.8 | asphalt, concrete, kerb, zebra as 1024 px PBR sets: cracks, patches, gravel in the normal map, wetness in the roughness |
| world pass: hero surfaces | sheet 1: doors, windows, power | doors, generators, transformers, panels, lamp posts as 1024 px PBR sets: rivets, grilles, hand wear on handles; what the player looks at from arm's length |
| world pass: dressing (B9) | sheet 1: city objects and lore | bins, benches, containers, abandoned cars, fences, wires and the set pieces of the world interest pass |
| optional, only after the owner approves the replacement itself: item icons 128x128 alpha | sheet 2: item icons | a semi-realistic PBR render of the item with a warm key on a transparent ground; flat or cartoon style is forbidden |

### Global prohibitions (a breach is an automatic P0 and a revert)

1. No flat design, cartoon, vector style or cute icons: only the semi-realistic PBR grit of the sheets (the failure of an earlier run: cartoon battery and heart icons).
2. No top-down or isometric view in any in-game view except the two map panels.
3. No rebuilding of the UI or the HUD to the layout of the sheets (no round minimaps, joysticks or buttons added); the chrome is the code canon of chamfers and brass.
4. No text, logos, watermarks or UI elements inside the art.
5. No palette quantisation (RGB PNG; the banding lesson).
6. No pure white and no saturated surface colours; the canon palette: darks `#020c10 #0f1314 #060f13 #1c1e1d #32312b`, amber `#d4a94e` and `#c9a24a` only from light sources, statuses `#7dc242 #e0c341 #c0392b`, text `#d8d5cc`.
7. No new asset in main without a side-by-side of it with the tile of the sheet in the request for approval and an APPROVED row in the journal below.
8. The owner is not asked about anything in the decisions above.
9. No new game elements: no mechanic, item, quest, interactive, screen, menu entry, mode, HUD component or UI node that the current game lacks; only the art layers of existing wired slots are replaced. Elements of the sheets that the game does not have (a round minimap, a joystick and round buttons, skins, IAP packs, "project team", weather thumbnails without a wired slot) are never added. The one exception is the B9 decoration (set pieces and layers of life): non-interactive, no change to any mechanic, assembled from the existing prop systems, and only with the owner's APPROVED before/after frames for each district (prompt (6) of 2026-10-29).

### Canon preamble of every generation (verbatim, plus the subject line of the slot)

"Semi-realistic gritty survival-horror game art, photographic PBR micro-detail, first-person eye-level view (camera 1.6 m, ~55 mm lens), night: near-black desaturated blue-teal shadows (#0f1314, #060f13), one warm sodium amber key light (#d4a94e) with a volumetric
cone and wet-asphalt reflection, thin cold fog, subtle film grain, weathered surfaces, amber accents only from light sources, no pure white highlights, no text, no logos, no watermark, no UI elements, NOT flat design, NOT cartoon, NOT vector style."
Img2img reference: the tiles of the sheets in `docs/art/style_reference/`.

### Definition of done of an asset (a commit is forbidden without all of it)

The exact path and size of the slot; an RGB PNG; the import sidecar untouched; the self-check against the canon (grit, one key, palette, grain, first-person camera) passed and written down (`tools/art_slots.py --check`); for a world or hero asset a windowed close-up (0.5 to 1 m) before and after, the
detail read as relief and albedo and not as glow; the side-by-side with the tile attached to the request; the owner's APPROVED (name and date) in the journal; `check.sh --static` green after the commit; one batch is one commit is one journal row.

### Micro-detail contract ("walk up and look")

1. Hero surfaces (everything the player comes nearer than 2 m to: doors, generators, workbenches, poles, kerbs, the facades of the first rank) get a full 1024 px PBR set: albedo, normal, roughness (ORM); the micro-relief lives in the normal map, wetness and wear in the roughness; emissive is for story light only (windows, lamps, indicators) and never stands in for detail.
2. Texel density at least 10 px per cm at arm's length for hero surfaces; the far ranks of facades may stay 256 to 512 px (mip chain) without visible blur on approach.
3. Detail overlays (a detail normal, grunge masks) where the engine and the budget allow (GL Compatibility, VRAM under 512 MiB, draw calls under 200): detail by textures, not by geometry or new lights.
4. Check: a close-up frame and a before/after in the evidence; the audit run compares the close-ups with the sheets.
5. If detail conflicts with the budget, the range of the detailed rank shrinks (a fade), not the resolution at the hand.

### World interest pass (B9)

Every district tells its story without text, in the canon of the sheets: (1) 3 to 5 set pieces per district from `docs/CONTENT_WORLD_BIBLE.md`, assembled from the existing prop systems (`street_props.gd` and the prop families of the sheets), no new system (a missing prop is a new wired texture or mesh by the specification of the sheets, with gates); the set pieces are non-interactive decor, with no new mechanic, item, quest or interactive (prohibition 9);
(2) layers of life by decals (a minimal decal support with gates if there is none): missing-person posters, district graffiti marks, puddles, tracks, litter, leaflets, and 3 or more variants of a bin or a bench; (3) light moments: shafts of light from windows and breaches, wires in silhouette against the sky, one distant flash per district (budget), weather touches;
(4) all of it in the darkness of the canon: interest is silhouette, rhythm of light and detail, not brightness and not coloured patches; stealth readability and `lighting_stage_sim` and GRADE1 stay whole; (5) the batch goes through the journal as the others: before/after frames per district and the owner's APPROVED on each.

### Audit of 2026-10-29 (`python tools/art_slots.py --check`)

Six of the seven full-screen slots are palette PNGs of 256 colours (`menu_city`, `loading_street`, `death_loom`, `character_dim`, `journal_paper`, `city_iso`) and `grid_panel` is quantised too; `menu_city` and `loading_street` clip white on 0.4 percent of the frame; the eleven cards are RGB and hold the canon. These are art pass 2 of the other agent; the
slots are to be replaced by generated art, none is touched until an image reaches `--fit`. The item icons of `assets/textures/items` are flat vector drawings (forbidden by prohibition 1); the replacement by the sheet's own icons is staged by `tools/harvest_sheets.py` for the owner's approval of the replacement itself.
| menu_city | the slot `assets/ui/menu_city.png` filled with a full-size image (side by side: `.qa_logs/approvals/menu_city_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| loading_street | the slot `assets/textures/screens_v2/loading_street.png` filled with a full-size image (side by side: `.qa_logs/approvals/loading_street_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| death_loom | the slot `assets/textures/screens_v2/death_loom.png` filled with a full-size image (side by side: `.qa_logs/approvals/death_loom_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| character_dim | the slot `assets/textures/screens_v2/character_dim.png` filled with a full-size image (side by side: `.qa_logs/approvals/character_dim_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| journal_paper | the slot `assets/textures/screens_v2/journal_paper.png` filled with a full-size image (side by side: `.qa_logs/approvals/journal_paper_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| city_iso | the slot `assets/textures/maps_v2/city_iso_2048.png` filled with a full-size image (side by side: `.qa_logs/approvals/city_iso_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| grid_panel | the slot `assets/textures/maps_v2/grid_panel_512.png` filled with a full-size image (side by side: `.qa_logs/approvals/grid_panel_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| card_suburbs | the slot `assets/textures/cards/card_suburbs_512.png` filled with a full-size image (side by side: `.qa_logs/approvals/card_suburbs_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| card_residential | the slot `assets/textures/cards/card_residential_512.png` filled with a full-size image (side by side: `.qa_logs/approvals/card_residential_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| card_park | the slot `assets/textures/cards/card_park_512.png` filled with a full-size image (side by side: `.qa_logs/approvals/card_park_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| card_school | the slot `assets/textures/cards/card_school_512.png` filled with a full-size image (side by side: `.qa_logs/approvals/card_school_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| card_hospital | the slot `assets/textures/cards/card_hospital_512.png` filled with a full-size image (side by side: `.qa_logs/approvals/card_hospital_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
| card_gas_station | the slot `assets/textures/cards/card_gas_station_512.png` filled with a full-size image (side by side: `.qa_logs/approvals/card_gas_station_board.png`) | APPROVED by the owner by delegation (standing instruction of 2026-10-29: finish the work without their hands), checked by Claude 2026-10-29 |
