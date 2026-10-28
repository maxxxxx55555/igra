# ART PASS 2 — the premium-noir repaint of the wired 2D art (2026-10-28)

Arena release agent, sandbox session. The complaint that started it: the game
reads flat and cheap — the menu was a low-contrast vector silhouette, the
screen backdrops and the district album cards were flat fills. Session 36's
own record agrees on the direction (KNOWN_ISSUES 2026-10-28: surfaces became
CC0 scans, "the monsters, the buildings and the props are still primitives").
This pass repaints every **already-wired 2D slot** in one coherent style, at
the exact paths and sizes the code loads, so zero game code changed and every
static gate stays green.

## Style canon: premium noir painterly

Dark blue-teal night; warm amber sodium-streetlight accents; wet-asphalt
reflections; volumetric light cones; drifting snow; film grain; high contrast
with deep shadows; painterly brushwork, no flat vector shapes; no text, no
logos, no watermarks inside the art. The chamfer/brass UI chrome canon
(`docs/UI_CONSISTENCY.md`, `docs/ART_UI_STYLE.md`) is untouched: this pass
changes backdrops and cards, never button chrome, icons, fonts or the SVG
icon family.

## What was replaced (path → slot, consumer)

| Path | Consumer |
|---|---|
| `assets/ui/menu_city.png` (1920×1080) | main menu hero, `main_menu.gd::_install_hero_bg_v2` |
| `assets/textures/screens_v2/loading_street.png` (1920×1080) | Loading card, `screens.gd:148` |
| `assets/textures/screens_v2/death_loom.png` (1920×1080) | death screen, `death_screen.gd` |
| `assets/textures/screens_v2/character_dim.png` (1920×1080) | stats backdrop, `stats_ui.gd:28` |
| `assets/textures/screens_v2/journal_paper.png` (1920×1080) | journal reader pane, `journal_ui.gd:110` |
| `assets/textures/maps_v2/city_iso_2048.png` (2048×2048) | city map backdrop, `city_map.gd:79` |
| `assets/textures/maps_v2/grid_panel_512.png` (512×512) | PowerGrid card, `screens.gd:149` |
| `assets/textures/cards/card_<d>_512.png` ×11 (512×512) | Collection album, `collection_ui.gd:105` |
| `assets/textures/cards/card_<d>_locked_512.png` ×11 | the locked state of the same cards |

Districts: suburbs, residential, park, school, hospital, gas_station, police,
warehouses, industrial, substation, power_station. Each card is a vignette of
that district's signature landmark (canopy, precinct, turbine hall, …) in the
style canon above.

## The locked variants are derived, not invented

The repo's own locked transform was measured from the previous pair
(`card_suburbs_512.png` → its locked file): per-channel affine
`out = k*in + c` with k = (0.439, 0.436, 0.527), c = (0.038, 0.052, 0.050) —
a 44 % darkening with a slight teal lift. The same affine was applied to each
new lit card, so locked cards stay one family with the old convention.

## Encoding

The five big screens and the city map are stored as 256-colour palette PNGs
with Floyd–Steinberg dither — the house format those slots already used
(`P` mode in the old files of the four screens; the menu hero and the map were RGB) — cutting the payload roughly in half with no
visible banding at their display sizes. Cards stay RGB.

## What this pass deliberately did NOT touch

- Environment textures (`assets/textures/environment/*`): already photoreal
  CC0 scans since art pass 1; regenerating them would be a downgrade.
- Light/fog/glow parameters (`scripts/world_env_setup.gd`): brightness is
  stealth balance in this game and is gated (lighting_stage_sim, GRADE1);
  touching it blind from a sandbox with no renderer is how balance dies.
- Monsters/buildings/props geometry: the primitives remain. The repo's own
  next step stands (KNOWN_ISSUES 2026-10-28): real models or a CC0 kit
  (Kenney, Quaternius), each with a licence row — an engine-and-eyes job.

## Verification and open items

- Verified here (fresh Linux clone, 2026-10-28): `bash tools/check.sh
  --static` green, `flow_check`, `scene_node_check`, `af5_check` 0 findings,
  `consistency_check` green (it measures the skyline facade palettes and the
  `assets/ui/ui_*.svg` family — neither touched), evidence in
  `.qa_logs/evidence/artpass2_static.out`.
- DONE (Session 37, engine machine, 2026-10-28): the eight store frames were re-shot at `04a3f8f1` after an import of the new textures (a first attempt shot before the import showed the old menu art
  and was thrown away: the engine loads the imported copy), `af3_frame_check` reads 8 frames and 0 fail, and the menu frame was read: the brass title and the buttons stay legible over the new hero.
- OPEN (owner): one eyes-on look at the menu on the target phone (title contrast over the new backdrop; the title keeps its deep outline from rc14).
- OPEN (owner): pick A/B/C of `docs/MUSIC_RIGHTS_MEMO.md`.
